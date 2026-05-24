import '../constants/platform_setting_keys.dart';
import '../models/enums/platform_setting_value_type.dart';
import '../models/platform_setting_definition.dart';

/// Shared validation and coercion for platform settings (no magic numbers in UI).
abstract final class PlatformSettingsValidators {
  PlatformSettingsValidators._();

  static const int maxFormatExtensionsPerList = 24;
  static const int maxExtensionTokenLength = 12;

  static String? validateAndCoerce(
    PlatformSettingDefinition def,
    Object? raw,
    void Function(Object? coerced) onCoerce,
  ) {
    switch (def.type) {
      case PlatformSettingValueType.boolean:
        final bool? v = _asBool(raw);
        if (v == null) return 'Must be true or false.';
        onCoerce(v);
        return null;
      case PlatformSettingValueType.integer:
        final int? v = _asInt(raw);
        if (v == null) return 'Must be a whole number.';
        if (def.min != null && v < def.min!) return 'Must be at least ${def.min}.';
        if (def.max != null && v > def.max!) return 'Must be at most ${def.max}.';
        onCoerce(v);
        return null;
      case PlatformSettingValueType.double:
        final double? v = _asDouble(raw);
        if (v == null) return 'Must be a number.';
        if (def.min != null && v < def.min!) return 'Must be at least ${def.min}.';
        if (def.max != null && v > def.max!) return 'Must be at most ${def.max}.';
        onCoerce(v);
        return null;
      case PlatformSettingValueType.stringList:
        final List<String>? list = _asStringList(raw);
        if (list == null) return 'Must be a list of extensions.';
        if (list.length > maxFormatExtensionsPerList) {
          return 'At most $maxFormatExtensionsPerList entries.';
        }
        for (final String s in list) {
          if (s.length > maxExtensionTokenLength) {
            return 'Each extension must be at most $maxExtensionTokenLength characters.';
          }
          if (!RegExp(r'^[a-z0-9]+$').hasMatch(s)) {
            return 'Use lowercase letters and numbers only (no dots).';
          }
        }
        onCoerce(list);
        return null;
    }
  }

  /// Leaderboard weights: optional soft check (inform UI; still allow save).
  static String? weightsBalanceHint(Map<String, dynamic> valuesByKey) {
    final double j = _asDouble(valuesByKey[PlatformSettingKeys.judgeScoreWeight]) ?? 0;
    final double i = _asDouble(valuesByKey[PlatformSettingKeys.innovationScoreWeight]) ?? 0;
    final double sum = j + i;
    if ((sum - 1.0).abs() > 0.05) {
      return 'Judge and innovation weights sum to ${sum.toStringAsFixed(2)}; consider balancing near 1.00.';
    }
    return null;
  }

  static bool? _asBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return null;
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static double? _asDouble(Object? raw) {
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }

  static List<String>? _asStringList(Object? raw) {
    if (raw == null) return <String>[];
    if (raw is List) {
      final out = <String>[];
      for (final Object? e in raw) {
        if (e == null) continue;
        final s = e.toString().trim().toLowerCase().replaceAll('.', '');
        if (s.isEmpty) continue;
        out.add(s);
      }
      return out;
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((s) => s.trim().toLowerCase().replaceAll('.', ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return null;
  }
}
