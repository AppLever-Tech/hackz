import '../enums/judge_type.dart';

class JudgeProfile {
  const JudgeProfile({
    this.evaluationDomains = const <String>[],
    this.judgeType,
  });

  final List<String> evaluationDomains;
  final JudgeType? judgeType;

  bool get isEmpty => evaluationDomains.isEmpty && judgeType == null;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (evaluationDomains.isNotEmpty) {
      map['evaluationDomains'] =
          evaluationDomains.map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList();
    }
    if (judgeType != null) map['judgeType'] = judgeType!.storageValue;
    return map;
  }

  factory JudgeProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const JudgeProfile();
    final List<String> domains = <String>[];
    final dynamic raw = map['evaluationDomains'];
    if (raw is List) {
      for (final dynamic item in raw) {
        final String value = item.toString().trim();
        if (value.isNotEmpty) domains.add(value);
      }
    }
    return JudgeProfile(
      evaluationDomains: domains,
      judgeType: JudgeType.fromRaw(map['judgeType'] as String?),
    );
  }

  JudgeProfile copyWith({
    List<String>? evaluationDomains,
    JudgeType? judgeType,
  }) {
    return JudgeProfile(
      evaluationDomains: evaluationDomains ?? this.evaluationDomains,
      judgeType: judgeType ?? this.judgeType,
    );
  }
}
