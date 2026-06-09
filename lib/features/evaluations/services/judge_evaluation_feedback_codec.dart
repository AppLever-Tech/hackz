import 'dart:convert';

/// Encodes structured evaluation metadata into [ScoreModel.feedback] while preserving plain-text remarks.
abstract final class JudgeEvaluationFeedbackCodec {
  static const String _marker = '[[hackz_eval_v1]]';

  static String compose({
    required int innovation,
    required int feasibility,
    required int impact,
    required String recommendation,
    required String remarks,
  }) {
    final meta = jsonEncode(<String, Object?>{
      'v': 1,
      'innovation': innovation.clamp(1, 10),
      'feasibility': feasibility.clamp(1, 10),
      'impact': impact.clamp(1, 10),
      'rec': recommendation.trim().isEmpty ? 'none' : recommendation.trim(),
    });
    final r = remarks.trim();
    if (r.isEmpty) return '$_marker$meta';
    return '$_marker$meta\n$r';
  }

  static JudgeEvaluationDecodedFeedback? tryDecode(String raw) {
    final t = raw.trim();
    if (!t.startsWith(_marker)) return null;
    final rest = t.substring(_marker.length).trim();
    final nl = rest.indexOf('\n');
    final jsonLine = nl < 0 ? rest : rest.substring(0, nl).trim();
    final remarks = nl < 0 ? '' : rest.substring(nl + 1).trim();
    try {
      final map = jsonDecode(jsonLine) as Map<String, dynamic>?;
      if (map == null) return null;
      if ((map['v'] as num?)?.toInt() != 1) return null;
      return JudgeEvaluationDecodedFeedback(
        innovation: ((map['innovation'] as num?) ?? 5).toInt().clamp(1, 10),
        feasibility: ((map['feasibility'] as num?) ?? 5).toInt().clamp(1, 10),
        impact: ((map['impact'] as num?) ?? 5).toInt().clamp(1, 10),
        recommendation: (map['rec'] as String?)?.trim() ?? 'none',
        remarks: remarks,
      );
    } catch (_) {
      return null;
    }
  }

  /// Human-readable remarks (strips structured prefix when present).
  static String displayRemarks(String raw) => tryDecode(raw)?.remarks ?? raw.trim();
}

class JudgeEvaluationDecodedFeedback {
  const JudgeEvaluationDecodedFeedback({
    required this.innovation,
    required this.feasibility,
    required this.impact,
    required this.recommendation,
    required this.remarks,
  });

  final int innovation;
  final int feasibility;
  final int impact;
  final String recommendation;
  final String remarks;
}
