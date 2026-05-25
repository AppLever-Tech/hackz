import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';
import '../constants/default_org_settings.dart';
import '../constants/org_setting_keys.dart';
import '../models/org_setting_definition.dart';
import 'org_settings_validators.dart';

/// Org-scoped runtime cache for organization settings.
///
/// Firestore path: `hkzOrganizations/{orgId}/settings/org_settings`.
///
/// Lifecycle:
///   1. Caller (College Admin dashboard or any reader) invokes
///      [ensureLoaded] passing the active `orgId`.
///   2. Service bootstraps the doc with defaults if absent, reads, and merges
///      any new keys introduced in [defaultOrgSettingDefinitions].
///   3. Reads / writes operate on the cached `orgId`. Changing `orgId`
///      transparently clears the cache and reloads.
///   4. [clearCache] resets everything (call on logout).
class OrgSettingsService extends ChangeNotifier {
  OrgSettingsService._();

  static final OrgSettingsService instance = OrgSettingsService._();

  /// Sub-collection name under `hkzOrganizations/{orgId}` that holds settings docs.
  static const String settingsSubcollection = 'settings';

  /// Doc id for the single per-org settings document.
  static const String orgSettingsDocId = 'org_settings';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, dynamic> _valuesByKey = <String, dynamic>{};
  final Map<String, OrgSettingDefinition> _defByKey = <String, OrgSettingDefinition>{
    for (final OrgSettingDefinition d in defaultOrgSettingDefinitions) d.key: d,
  };

  String? _orgId;
  bool _loading = false;
  String? _error;
  Future<void>? _loadFuture;

  bool get isLoading => _loading;
  String? get lastError => _error;
  bool get isLoaded => _valuesByKey.isNotEmpty;
  String? get currentOrgId => _orgId;

  Map<String, dynamic> get valuesSnapshot => Map<String, dynamic>.unmodifiable(_valuesByKey);

  OrgSettingDefinition? definitionFor(String key) => _defByKey[key];

  /// Clears in-memory cache (call on logout).
  void clearCache() {
    _valuesByKey.clear();
    _orgId = null;
    _error = null;
    _loading = false;
    _loadFuture = null;
    notifyListeners();
  }

  /// Loads org settings from Firestore (bootstraps the doc if absent and
  /// merges any newly introduced keys from Dart defaults). Cached after the
  /// first call for the same [orgId].
  Future<void> ensureLoaded({required String orgId, bool force = false}) {
    final String trimmed = orgId.trim();
    if (trimmed.isEmpty) {
      _error = 'Missing orgId for settings load.';
      _valuesByKey.clear();
      _orgId = null;
      notifyListeners();
      return Future<void>.value();
    }

    final bool orgChanged = _orgId != trimmed;
    if (orgChanged || force) {
      _orgId = trimmed;
      _valuesByKey.clear();
      _error = null;
      _loadFuture = null;
      notifyListeners();
    }
    if (isLoaded && !force && !orgChanged) {
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
        debugPrint('OrgSettingsService load failed: $e\n$st');
      }
    } finally {
      _loading = false;
      _loadFuture = null;
      notifyListeners();
    }
  }

  DocumentReference<Map<String, dynamic>> _configRefFor(String orgId) {
    return _db
        .collection(FirestoreUtils.hkzOrganizations)
        .doc(orgId)
        .collection(settingsSubcollection)
        .doc(orgSettingsDocId);
  }

  DocumentReference<Map<String, dynamic>> get _configRef {
    final String? id = _orgId;
    if (id == null || id.isEmpty) {
      throw StateError('OrgSettingsService not loaded for any org.');
    }
    return _configRefFor(id);
  }

  Future<void> _bootstrapIfAbsent() async {
    final DocumentReference<Map<String, dynamic>> ref = _configRef;
    await _db.runTransaction((Transaction txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) return;
      txn.set(ref, <String, dynamic>{
        'schemaVersion': kOrgSettingsSchemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': defaultOrgSettingsFirestoreEntries(),
      });
    });
  }

  Future<void> _readAndMerge() async {
    final snap = await _configRef.get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Org settings document missing after bootstrap.');
    }
    final data = snap.data()!;
    _applySettingsArray(data['settings']);

    final List<Map<String, dynamic>> missing = <Map<String, dynamic>>[];
    for (final OrgSettingDefinition d in defaultOrgSettingDefinitions) {
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
      final OrgSettingDefinition? def = _defByKey[key];
      if (def == null) continue;
      Object? coerced;
      final String? err = OrgSettingsValidators.validateAndCoerce(def, item['value'], (c) => coerced = c);
      _valuesByKey[key] = err != null ? def.defaultValue : coerced;
    }
  }

  void _normalizeDependentDefaults() {
    final OrgSettingDefinition? minD = _defByKey[OrgSettingKeys.minStudentsPerTeam];
    final OrgSettingDefinition? maxD = _defByKey[OrgSettingKeys.maxStudentsPerTeam];
    if (minD != null && maxD != null) {
      final int minV = _asInt(_valuesByKey[minD.key]) ?? minD.defaultValue as int;
      final int maxV = _asInt(_valuesByKey[maxD.key]) ?? maxD.defaultValue as int;
      if (minV > maxV) {
        _valuesByKey[maxD.key] = minV;
      }
    }
    final OrgSettingDefinition? jDef = _defByKey[OrgSettingKeys.minJudgesPerIdea];
    final OrgSettingDefinition? xDef = _defByKey[OrgSettingKeys.maxJudgesPerIdea];
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
    for (final OrgSettingDefinition d in defaultOrgSettingDefinitions) {
      entries.add(<String, dynamic>{
        'key': d.key,
        'displayName': d.displayName,
        'value': _valuesByKey[d.key] ?? d.defaultValue,
      });
    }
    await _configRef.set(
      <String, dynamic>{
        'schemaVersion': kOrgSettingsSchemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': entries,
      },
      SetOptions(merge: true),
    );
  }

  /// Validates, updates cache optimistically, persists. Reverts cache on failure.
  Future<String?> updateValue(String key, Object? value) async {
    final OrgSettingDefinition? def = _defByKey[key];
    if (def == null) return 'Unknown setting.';
    if (_orgId == null || _orgId!.isEmpty) return 'Org settings not loaded.';

    Object? coerced;
    final String? err = OrgSettingsValidators.validateAndCoerce(def, value, (c) => coerced = c);
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

  String? weightsHint() => OrgSettingsValidators.weightsBalanceHint(_valuesByKey);

  /// One-shot seed for a freshly created organization. Writes the default
  /// settings document if it doesn't already exist. Best-effort: callers can
  /// also rely on lazy bootstrap inside [ensureLoaded].
  ///
  /// Used by the org creation flow so new colleges land with sane defaults
  /// before any admin first opens the dashboard.
  static Future<void> seedFor(String orgId) async {
    final String trimmed = orgId.trim();
    if (trimmed.isEmpty) return;
    final db = FirebaseFirestore.instance;
    final DocumentReference<Map<String, dynamic>> ref = db
        .collection(FirestoreUtils.hkzOrganizations)
        .doc(trimmed)
        .collection(settingsSubcollection)
        .doc(orgSettingsDocId);
    try {
      await db.runTransaction((Transaction txn) async {
        final snap = await txn.get(ref);
        if (snap.exists) return;
        txn.set(ref, <String, dynamic>{
          'schemaVersion': kOrgSettingsSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
          'settings': defaultOrgSettingsFirestoreEntries(),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrgSettingsService.seedFor($trimmed) failed: $e');
      }
    }
  }
}
