import 'enums/org_setting_value_type.dart';

/// Metadata for one org-scoped rule (defaults + UI hints).
/// Runtime values live in Firestore at `hkzOrganizations/{orgId}/settings/org_settings`.
class OrgSettingDefinition {
  const OrgSettingDefinition({
    required this.key,
    required this.displayName,
    required this.type,
    required this.defaultValue,
    required this.sectionKey,
    required this.sectionTitle,
    required this.groupKey,
    required this.groupTitle,
    this.description,
    this.min,
    this.max,
    this.step,
    this.segmentLabels,
    this.segmentValues,
  });

  final String key;
  final String displayName;
  final OrgSettingValueType type;
  final Object? defaultValue;
  final String sectionKey;
  final String sectionTitle;
  final String groupKey;
  final String groupTitle;
  final String? description;
  final num? min;
  final num? max;
  final num? step;

  /// For [OrgSettingValueType.boolean] toggles shown as two-option chips (optional).
  final List<String>? segmentLabels;
  final List<String>? segmentValues;
}
