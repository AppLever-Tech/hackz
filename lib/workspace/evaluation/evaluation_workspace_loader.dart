import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/idea_model.dart';
import '../../models/payment_model.dart';
import '../../models/problem_model.dart';
import '../../models/score_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/judge_evaluation_feedback_codec.dart';
import '../../utils/leaderboard_ranking_engine.dart';
import '../../constants/status_styles.dart';

enum EvaluationWorkspaceScope { singleJudge, ideaAggregate }

class EvaluationCriterionScore {
  const EvaluationCriterionScore({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final double value;
  final int maxValue;
}

class EvaluationJudgeEntry {
  const EvaluationJudgeEntry({
    required this.scoreId,
    required this.judgeId,
    required this.judgeName,
    required this.overallScore,
    required this.evaluatedAt,
    required this.innovation,
    required this.feasibility,
    required this.impact,
    required this.recommendation,
    required this.remarks,
  });

  final String scoreId;
  final String judgeId;
  final String judgeName;
  final double overallScore;
  final DateTime evaluatedAt;
  final int innovation;
  final int feasibility;
  final int impact;
  final String recommendation;
  final String remarks;
}

class EvaluationWorkspaceViewModel {
  const EvaluationWorkspaceViewModel({
    required this.evaluationId,
    required this.scope,
    required this.idea,
    required this.ideaTitle,
    required this.teamName,
    required this.teamId,
    required this.problem,
    required this.evaluationStatusLabel,
    required this.totalScore,
    required this.evaluatedAt,
    required this.criteria,
    required this.judgeEntries,
    required this.strengths,
    required this.improvements,
    required this.recommendationSummary,
    required this.normalizedScore,
    required this.rankingContribution,
    required this.reviewCompletionLabel,
  });

  final String evaluationId;
  final EvaluationWorkspaceScope scope;
  final IdeaModel idea;
  final String ideaTitle;
  final String teamName;
  final String teamId;
  final ProblemModel? problem;
  final String evaluationStatusLabel;
  final double totalScore;
  final DateTime evaluatedAt;
  final List<EvaluationCriterionScore> criteria;
  final List<EvaluationJudgeEntry> judgeEntries;
  final List<String> strengths;
  final List<String> improvements;
  final String recommendationSummary;
  final double normalizedScore;
  final double rankingContribution;
  final String reviewCompletionLabel;

  EvaluationJudgeEntry? get primaryJudge =>
      judgeEntries.isEmpty ? null : judgeEntries.first;
}

abstract final class EvaluationWorkspaceLoader {
  static const LeaderboardRankingEngine _ranking = LeaderboardRankingEngine();

  static Future<EvaluationWorkspaceViewModel> load(String evaluationId) async {
    final String id = evaluationId.trim();
    if (id.isEmpty) {
      throw ArgumentError('evaluationId must be non-empty');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> scoreDoc =
        await db.collection(FirestoreUtils.hkzScores).doc(id).get();

    if (scoreDoc.exists && scoreDoc.data() != null) {
      final ScoreModel score = ScoreModel.fromMap(scoreDoc.id, scoreDoc.data()!);
      return _loadSingle(score);
    }

    return _loadIdeaAggregate(db, id);
  }

  static Future<EvaluationWorkspaceViewModel> _loadSingle(ScoreModel score) async {
    final String ideaId = score.ideaId.trim();
    if (ideaId.isEmpty) {
      throw StateError('Score is not linked to an idea');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await db.collection(FirestoreUtils.hkzIdeas).doc(ideaId).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Idea not found for evaluation');
    }

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final UserModel? judge = await FirestoreUtils.fetchUser(score.judgeId.trim());
    final String judgeName = judge == null
        ? (score.judgeId.trim().isEmpty ? 'Judge' : score.judgeId.trim())
        : userDisplayName(judge);

    final _ParsedScore parsed = _parseScore(score, judgeName);
    final _IdeaContext ctx = await _loadIdeaContext(idea);
    final PaymentModel? payment = await _loadPayment(db, ideaId);

    final double normalized = _ranking.normalizedEvaluation(score.score);
    final double composite = _ranking.compositeIdeaScore(
      avgJudgeScore: score.score,
      idea: idea,
      problem: ctx.problem,
      payment: payment,
    );

    return EvaluationWorkspaceViewModel(
      evaluationId: score.scoreId,
      scope: EvaluationWorkspaceScope.singleJudge,
      idea: idea,
      ideaTitle: ctx.ideaTitle,
      teamName: ctx.teamName,
      teamId: ctx.teamId,
      problem: ctx.problem,
      evaluationStatusLabel: StatusStyles.labelForIdeaStatus(idea.status),
      totalScore: score.score,
      evaluatedAt: score.createdAt,
      criteria: parsed.criteria,
      judgeEntries: <EvaluationJudgeEntry>[parsed.entry],
      strengths: parsed.strengths,
      improvements: parsed.improvements,
      recommendationSummary: parsed.recommendationLabel,
      normalizedScore: normalized,
      rankingContribution: composite,
      reviewCompletionLabel: '1 of 1 review complete',
    );
  }

  static Future<EvaluationWorkspaceViewModel> _loadIdeaAggregate(
    FirebaseFirestore db,
    String ideaId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await db.collection(FirestoreUtils.hkzIdeas).doc(ideaId).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Evaluation not found');
    }

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final String orgId = idea.orgId.trim();

    final QuerySnapshot<Map<String, dynamic>> scoresSnap = orgId.isEmpty
        ? await db.collection(FirestoreUtils.hkzScores).limit(0).get()
        : await db
            .collection(FirestoreUtils.hkzScores)
            .where('orgId', isEqualTo: orgId)
            .where('ideaId', isEqualTo: ideaId)
            .get();

    final List<ScoreModel> scores = scoresSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => ScoreModel.fromMap(d.id, d.data()))
        .toList(growable: false)
      ..sort((ScoreModel a, ScoreModel b) => b.createdAt.compareTo(a.createdAt));

    if (scores.isEmpty) {
      throw StateError('No evaluation records for this idea');
    }

    final _IdeaContext ctx = await _loadIdeaContext(idea);
    final PaymentModel? payment = await _loadPayment(db, ideaId);

    final List<EvaluationJudgeEntry> judges = <EvaluationJudgeEntry>[];
    int innovSum = 0;
    int feasSum = 0;
    int impactSum = 0;
    int criteriaCount = 0;
    final List<String> allStrengths = <String>[];
    final List<String> allImprovements = <String>[];
    final List<String> recommendations = <String>[];

    for (final ScoreModel score in scores) {
      final UserModel? judge = await FirestoreUtils.fetchUser(score.judgeId.trim());
      final String judgeName = judge == null
          ? (score.judgeId.trim().isEmpty ? 'Judge' : score.judgeId.trim())
          : userDisplayName(judge);
      final _ParsedScore parsed = _parseScore(score, judgeName);
      judges.add(parsed.entry);
      innovSum += parsed.entry.innovation;
      feasSum += parsed.entry.feasibility;
      impactSum += parsed.entry.impact;
      criteriaCount++;
      allStrengths.addAll(parsed.strengths);
      allImprovements.addAll(parsed.improvements);
      if (parsed.recommendationLabel != 'No recommendation') {
        recommendations.add('${parsed.entry.judgeName}: ${parsed.recommendationLabel}');
      }
    }

    final double avgScore = scores.map((ScoreModel s) => s.score).reduce((double a, double b) => a + b) / scores.length;
    final int n = criteriaCount == 0 ? 1 : criteriaCount;
    final List<EvaluationCriterionScore> criteria = <EvaluationCriterionScore>[
      EvaluationCriterionScore(label: 'Innovation', value: innovSum / n, maxValue: 10),
      EvaluationCriterionScore(label: 'Feasibility', value: feasSum / n, maxValue: 10),
      EvaluationCriterionScore(label: 'Impact', value: impactSum / n, maxValue: 10),
    ];

    final double normalized = _ranking.normalizedEvaluation(avgScore);
    final double composite = _ranking.compositeIdeaScore(
      avgJudgeScore: avgScore,
      idea: idea,
      problem: ctx.problem,
      payment: payment,
    );

    return EvaluationWorkspaceViewModel(
      evaluationId: ideaId,
      scope: EvaluationWorkspaceScope.ideaAggregate,
      idea: idea,
      ideaTitle: ctx.ideaTitle,
      teamName: ctx.teamName,
      teamId: ctx.teamId,
      problem: ctx.problem,
      evaluationStatusLabel: StatusStyles.labelForIdeaStatus(idea.status),
      totalScore: avgScore,
      evaluatedAt: scores.first.createdAt,
      criteria: criteria,
      judgeEntries: judges,
      strengths: _dedupe(allStrengths).take(6).toList(growable: false),
      improvements: _dedupe(allImprovements).take(6).toList(growable: false),
      recommendationSummary: recommendations.isEmpty
          ? 'No consolidated recommendation'
          : recommendations.join(' · '),
      normalizedScore: normalized,
      rankingContribution: composite,
      reviewCompletionLabel: '${scores.length} review${scores.length == 1 ? '' : 's'} recorded',
    );
  }

  static Future<_IdeaContext> _loadIdeaContext(IdeaModel idea) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final TeamModel? team = idea.teamId.trim().isEmpty
        ? null
        : await db.collection(FirestoreUtils.hkzTeams).doc(idea.teamId.trim()).get().then((doc) {
            if (!doc.exists || doc.data() == null) return null;
            return TeamModel.fromMap(doc.id, doc.data()!);
          });
    final ProblemModel? problem = idea.problemId.trim().isEmpty
        ? null
        : await FirestoreUtils.fetchProblemById(idea.problemId.trim());

    final String ideaTitle = idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim();
    final String teamName = team?.teamName.trim().isNotEmpty == true
        ? team!.teamName.trim()
        : (idea.teamId.trim().isEmpty ? '—' : idea.teamId.trim());

    return _IdeaContext(
      ideaTitle: ideaTitle,
      teamName: teamName,
      teamId: team?.teamId ?? idea.teamId,
      problem: problem,
    );
  }

  static Future<PaymentModel?> _loadPayment(FirebaseFirestore db, String ideaId) async {
    final DocumentSnapshot<Map<String, dynamic>> primary =
        await db.collection(FirestoreUtils.hkzPayments).doc(ideaId).get();
    if (primary.exists && primary.data() != null) {
      return PaymentModel.fromMap(primary.id, primary.data()!);
    }
    return null;
  }

  static _ParsedScore _parseScore(ScoreModel score, String judgeName) {
    final JudgeEvaluationDecodedFeedback? decoded =
        JudgeEvaluationFeedbackCodec.tryDecode(score.feedback);
    final int innovation = decoded?.innovation ?? score.score.round().clamp(1, 10);
    final int feasibility = decoded?.feasibility ?? score.score.round().clamp(1, 10);
    final int impact = decoded?.impact ?? score.score.round().clamp(1, 10);
    final String remarks = JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback);
    final String rec = decoded?.recommendation ?? 'none';
    final String recLabel = _recommendationLabel(rec);

    final List<String> strengths = <String>[];
    final List<String> improvements = <String>[];

    if (innovation >= 7) strengths.add('Strong innovation signal ($innovation/10)');
    if (feasibility >= 7) strengths.add('Solid feasibility ($feasibility/10)');
    if (impact >= 7) strengths.add('High impact potential ($impact/10)');
    if (innovation < 6) improvements.add('Innovation may need more differentiation ($innovation/10)');
    if (feasibility < 6) improvements.add('Feasibility requires refinement ($feasibility/10)');
    if (impact < 6) improvements.add('Impact narrative could be stronger ($impact/10)');

    if (rec == 'revise') improvements.add('Judge requested revisions');
    if (rec == 'reject') improvements.add('Not recommended at this stage');
    if (rec == 'advance') strengths.add('Recommended to advance');

    if (remarks.trim().isNotEmpty) {
      strengths.add(remarks.trim());
    }

    return _ParsedScore(
      entry: EvaluationJudgeEntry(
        scoreId: score.scoreId,
        judgeId: score.judgeId,
        judgeName: judgeName,
        overallScore: score.score,
        evaluatedAt: score.createdAt,
        innovation: innovation,
        feasibility: feasibility,
        impact: impact,
        recommendation: rec,
        remarks: remarks,
      ),
      criteria: <EvaluationCriterionScore>[
        EvaluationCriterionScore(label: 'Innovation', value: innovation.toDouble(), maxValue: 10),
        EvaluationCriterionScore(label: 'Feasibility', value: feasibility.toDouble(), maxValue: 10),
        EvaluationCriterionScore(label: 'Impact', value: impact.toDouble(), maxValue: 10),
      ],
      strengths: strengths,
      improvements: improvements,
      recommendationLabel: recLabel,
    );
  }

  static String _recommendationLabel(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'advance' => 'Advance / strong merit',
      'revise' => 'Request revisions',
      'reject' => 'Not recommended',
      _ => 'No recommendation',
    };
  }

  static List<String> _dedupe(List<String> items) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String item in items) {
      final String key = item.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(item.trim());
    }
    return out;
  }
}

class _IdeaContext {
  const _IdeaContext({
    required this.ideaTitle,
    required this.teamName,
    required this.teamId,
    required this.problem,
  });

  final String ideaTitle;
  final String teamName;
  final String teamId;
  final ProblemModel? problem;
}

class _ParsedScore {
  const _ParsedScore({
    required this.entry,
    required this.criteria,
    required this.strengths,
    required this.improvements,
    required this.recommendationLabel,
  });

  final EvaluationJudgeEntry entry;
  final List<EvaluationCriterionScore> criteria;
  final List<String> strengths;
  final List<String> improvements;
  final String recommendationLabel;
}
