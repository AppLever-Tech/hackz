import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../constants/default_platform_settings.dart';
import '../constants/platform_setting_keys.dart';
import '../models/platform_setting_definition.dart';
import 'firestore_utils.dart';
import 'platform_settings_validators.dart';

/// Runtime source of truth: Firestore `hkzPlatformSettings/config` after first bootstrap.
class PlatformSettingsService extends ChangeNotifier {
  PlatformSettingsService._();

  static final PlatformSettingsService instance = PlatformSettingsService._();

  static const String _configDocId = 'config';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, dynamic> _valuesByKey = <String, dynamic>{};
  final Map<String, PlatformSettingDefinition> _defByKey = <String, PlatformSettingDefinition>{
    for (final PlatformSettingDefinition d in defaultPlatformSettingDefinitions) d.key: d,
  };

  bool _loading = false;
  String? _error;
  Future<void>? _loadFuture;

  bool get isLoading => _loading;
  String? get lastError => _error;
  bool get isLoaded => _valuesByKey.isNotEmpty;

  Map<String, dynamic> get valuesSnapshot => Map<String, dynamic>.unmodifiable(_valuesByKey);

  PlatformSettingDefinition? definitionFor(String key) => _defByKey[key];

  /// Clears in-memory cache (call on logout).
  void clearCache() {
    _valuesByKey.clear();
    _error = null;
    _loading = false;
    _loadFuture = null;
    notifyListeners();
  }

  /// Loads from Firestore, bootstraps doc if missing, merges new keys from Dart defaults. Non-blocking friendly.
  Future<void> ensureLoaded({bool force = false}) {
    if (force) {
      _loadFuture = null;
      _valuesByKey.clear();
      _error = null;
      notifyListeners();
    }
    if (isLoaded && !force) {
      return Future<void>.value();
    }
    return _loadFuture ??= _loadInternal();
  }

  Future<void> _loadInternal() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _bootstrapIfAbsent();
      await _readAndMerge();
    } catch (e, st) {
      _error = e.toString();
      _valuesByKey.clear();
      if (kDebugMode) {
        debugPrint('PlatformSettingsService load failed: $e\n$st');
      }
    } finally {
      _loading = false;
      _loadFuture = null;
      notifyListeners();
    }
  }

  DocumentReference<Map<String, dynamic>> get _configRef =>
      _db.collection(FirestoreUtils.hkzPlatformSettings).doc(_configDocId);

  Future<void> _bootstrapIfAbsent() async {
    await _db.runTransaction((Transaction txn) async {
      final snap = await txn.get(_configRef);
      if (snap.exists) return;
      txn.set(_configRef, <String, dynamic>{
        'schemaVersion': kPlatformSettingsSchemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': defaultPlatformSettingsFirestoreEntries(),
      });
    });
  }

  Future<void> _readAndMerge() async {
    final snap = await _configRef.get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Platform settings document missing after bootstrap.');
    }
    final data = snap.data()!;
    _applySettingsArray(data['settings']);

    final List<Map<String, dynamic>> missing = <Map<String, dynamic>>[];
    for (final PlatformSettingDefinition d in defaultPlatformSettingDefinitions) {
      if (!_valuesByKey.containsKey(d.key)) {
        missing.add(<String, dynamic>{
          'key': d.key,
          'displayName': d.displayName,
          'value': d.defaultValue,
        });
        _valuesByKey[d.key] = d.defaultValue;
      }
    }

    if (missing.isNotEmpty) {
      await _persistFullSettingsArray();
    }

    _normalizeDependentDefaults();
  }

  void _applySettingsArray(Object? raw) {
    _valuesByKey.clear();
    if (raw is! List) return;
    for (final Object? item in raw) {
      if (item is! Map) continue;
      final String key = (item['key'] as String?)?.trim() ?? '';
      if (key.isEmpty) continue;
      final PlatformSettingDefinition? def = _defByKey[key];
      if (def == null) continue;
      Object? coerced;
      final String? err = PlatformSettingsValidators.validateAndCoerce(def, item['value'], (c) => coerced = c);
      _valuesByKey[key] = err != null ? def.defaultValue : coerced;
    }
  }

  void _normalizeDependentDefaults() {
    final PlatformSettingDefinition? minD = _defByKey[PlatformSettingKeys.minStudentsPerTeam];
    final PlatformSettingDefinition? maxD = _defByKey[PlatformSettingKeys.maxStudentsPerTeam];
    if (minD != null && maxD != null) {
      final int minV = _asInt(_valuesByKey[minD.key]) ?? minD.defaultValue as int;
      final int maxV = _asInt(_valuesByKey[maxD.key]) ?? maxD.defaultValue as int;
      if (minV > maxV) {
        _valuesByKey[maxD.key] = minV;
      }
    }
    final PlatformSettingDefinition? jDef = _defByKey[PlatformSettingKeys.minJudgesPerIdea];
    final PlatformSettingDefinition? xDef = _defByKey[PlatformSettingKeys.maxJudgesPerIdea];
    if (jDef != null && xDef != null) {
      final int j = _asInt(_valuesByKey[jDef.key]) ?? jDef.defaultValue as int;
      final int x = _asInt(_valuesByKey[xDef.key]) ?? xDef.defaultValue as int;
      if (j > x) {
        _valuesByKey[xDef.key] = j;
      }
    }
  }

  int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  Future<void> _persistFullSettingsArray() async {
    final List<Map<String, dynamic>> entries = <Map<String, dynamic>>[];
    for (final PlatformSettingDefinition d in defaultPlatformSettingDefinitions) {
      entries.add(<String, dynamic>{
        'key': d.key,
        'displayName': d.displayName,
        'value': _valuesByKey[d.key] ?? d.defaultValue,
      });
    }
    await _configRef.set(
      <String, dynamic>{
        'schemaVersion': kPlatformSettingsSchemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': entries,
      },
      SetOptions(merge: true),
    );
  }

  /// Validates, updates cache optimistically, persists. Reverts cache on failure.
  Future<String?> updateValue(String key, Object? value) async {
    final PlatformSettingDefinition? def = _defByKey[key];
    if (def == null) return 'Unknown setting.';

    Object? coerced;
    final String? err = PlatformSettingsValidators.validateAndCoerce(def, value, (c) => coerced = c);
    if (err != null) return err;

    final Object? previous = _valuesByKey[key];
    _valuesByKey[key] = coerced;
    _normalizeDependentDefaults();
    notifyListeners();

    try {
      await _persistFullSettingsArray();
    } catch (e) {
      _valuesByKey[key] = previous;
      _normalizeDependentDefaults();
      notifyListeners();
      return e.toString();
    }
    return null;
  }

  String? weightsHint() => PlatformSettingsValidators.weightsBalanceHint(_valuesByKey);
}
