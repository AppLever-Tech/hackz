import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/evaluations/models/evaluation_criterion.dart';
import '../../features/evaluations/models/evaluation_template.dart';
import '../../features/evaluations/services/evaluation_templates_service.dart';
import '../../features/org_settings/services/org_settings_service.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../models/payment_model.dart';
import '../../features/problems/models/problem_model.dart';
import '../../models/score_model.dart';
import '../../features/team/models/team_model.dart';
import '../../features/user/models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/judge_evaluation_feedback_codec.dart';
import '../../utils/leaderboard_ranking_engine.dart';
import '../../constants/status_styles.dart';

enum EvaluationWorkspaceScope { singleJudge, ideaAggregate }

class EvaluationCriterionScore {
  const EvaluationCriterionScore({
    required this.criterionId,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  /// Stable id of the source criterion. May be empty for legacy aggregate
  /// rollups that only have label/value/max.
  final String criterionId;
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
    required this.criteria,
    required this.criterionComments,
    required this.recommendation,
    required this.remarks,
    required this.templateName,
  });

  final String scoreId;
  final String judgeId;
  final String judgeName;
  final double overallScore;
  final DateTime evaluatedAt;

  /// Per-criterion mini scores authored by this judge.
  final List<EvaluationCriterionScore> criteria;

  /// Optional per-criterion comments (criterionId → comment).
  final Map<String, String> criterionComments;

  /// Recommendation pulled from legacy v1 codec; `'none'` for new records.
  final String recommendation;

  final String remarks;
  final String templateName;
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
    required this.scoringScale,
    required this.templateName,
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

  /// Overall scoring scale (e.g. 10). Used by UI to show `X / N`.
  final int scoringScale;

  /// Display name of the source template ("Mixed" when judges used different
  /// templates in an aggregate view).
  final String templateName;

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

    await OrgSettingsService.instance.ensureLoaded(orgId: score.orgId);

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

    final EvaluationTemplate template =
        EvaluationTemplatesService.resolveTemplate(score.templateId);
    final _ParsedScore parsed = _parseScore(score, judgeName, template);
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
      scoringScale: template.scoringScale,
      templateName: template.templateName,
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

    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);

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
    final List<String> allStrengths = <String>[];
    final List<String> allImprovements = <String>[];
    final List<String> recommendations = <String>[];
    // Aggregator: criterionId → (label, max, sum, count). Last seen label/max wins.
    final Map<String, _CriterionAccumulator> agg = <String, _CriterionAccumulator>{};
    final Set<String> usedTemplateIds = <String>{};

    for (final ScoreModel score in scores) {
      final UserModel? judge = await FirestoreUtils.fetchUser(score.judgeId.trim());
      final String judgeName = judge == null
          ? (score.judgeId.trim().isEmpty ? 'Judge' : score.judgeId.trim())
          : userDisplayName(judge);
      final EvaluationTemplate scoreTemplate =
          EvaluationTemplatesService.resolveTemplate(score.templateId);
      usedTemplateIds.add(scoreTemplate.templateId);
      final _ParsedScore parsed = _parseScore(score, judgeName, scoreTemplate);
      judges.add(parsed.entry);
      allStrengths.addAll(parsed.strengths);
      allImprovements.addAll(parsed.improvements);
      if (parsed.recommendationLabel != 'No recommendation') {
        recommendations.add('${parsed.entry.judgeName}: ${parsed.recommendationLabel}');
      }
      for (final EvaluationCriterionScore c in parsed.criteria) {
        final _CriterionAccumulator? prev = agg[c.criterionId.isEmpty ? c.label : c.criterionId];
        final String key = c.criterionId.isEmpty ? c.label : c.criterionId;
        if (prev == null) {
          agg[key] = _CriterionAccumulator(
            label: c.label,
            maxValue: c.maxValue,
            sum: c.value,
            count: 1,
          );
        } else {
          agg[key] = _CriterionAccumulator(
            label: c.label,
            maxValue: c.maxValue,
            sum: prev.sum + c.value,
            count: prev.count + 1,
          );
        }
      }
    }

    final double avgScore = scores.map((ScoreModel s) => s.score).reduce((double a, double b) => a + b) / scores.length;
    final List<EvaluationCriterionScore> criteria = agg.entries
        .map((MapEntry<String, _CriterionAccumulator> e) => EvaluationCriterionScore(
              criterionId: e.key,
              label: e.value.label,
              value: e.value.count == 0 ? 0 : e.value.sum / e.value.count,
              maxValue: e.value.maxValue,
            ))
        .toList(growable: false);

    final double normalized = _ranking.normalizedEvaluation(avgScore);
    final double composite = _ranking.compositeIdeaScore(
      avgJudgeScore: avgScore,
      idea: idea,
      problem: ctx.problem,
      payment: payment,
    );

    // Use the first judge's template's scale (they should all be on the same
    // org scale today); "Mixed" name when judges used different templates.
    final EvaluationTemplate dominant =
        EvaluationTemplatesService.resolveTemplate(scores.first.templateId);
    final String templateName = usedTemplateIds.length > 1 ? 'Mixed templates' : dominant.templateName;

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
      scoringScale: dominant.scoringScale,
      templateName: templateName,
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

  static _ParsedScore _parseScore(
    ScoreModel score,
    String judgeName,
    EvaluationTemplate template,
  ) {
    // Build the per-criterion list. New records have structured
    // `score.criteriaScores`; legacy v1 records get their three known fields
    // mapped onto the template's matching criterion ids.
    final Map<String, double> effectiveScores = <String, double>{};
    if (score.criteriaScores.isNotEmpty) {
      effectiveScores.addAll(score.criteriaScores);
    }
    final JudgeEvaluationDecodedFeedback? legacy =
        JudgeEvaluationFeedbackCodec.tryDecode(score.feedback);
    if (effectiveScores.isEmpty && legacy != null) {
      void seedLegacy(String id, int v) {
        if (!effectiveScores.containsKey(id)) effectiveScores[id] = v.toDouble();
      }

      for (final EvaluationCriterion c in template.criteria) {
        switch (c.criterionId) {
          case 'innovation':
            seedLegacy(c.criterionId, legacy.innovation);
            break;
          case 'feasibility':
            seedLegacy(c.criterionId, legacy.feasibility);
            break;
          case 'impact':
            seedLegacy(c.criterionId, legacy.impact);
            break;
        }
      }
    }

    final List<EvaluationCriterionScore> criteria = <EvaluationCriterionScore>[];
    for (final EvaluationCriterion c in template.orderedCriteria) {
      if (!effectiveScores.containsKey(c.criterionId)) continue;
      final double v = effectiveScores[c.criterionId]!
          .clamp(c.minScore.toDouble(), c.maxScore.toDouble());
      criteria.add(
        EvaluationCriterionScore(
          criterionId: c.criterionId,
          label: c.title,
          value: v,
          maxValue: c.maxScore,
        ),
      );
    }

    // Also surface any criterion the score carries that the (resolved)
    // template no longer contains — happens when admins remove criteria after
    // historical scores were recorded.
    final Set<String> renderedIds = criteria.map((c) => c.criterionId).toSet();
    for (final MapEntry<String, double> e in effectiveScores.entries) {
      if (renderedIds.contains(e.key)) continue;
      criteria.add(
        EvaluationCriterionScore(
          criterionId: e.key,
          label: e.key,
          value: e.value,
          maxValue: template.scoringScale,
        ),
      );
    }

    final String remarks = legacy != null
        ? JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback)
        : score.feedback.trim();
    final String rec = legacy?.recommendation ?? 'none';
    final String recLabel = _recommendationLabel(rec);

    final List<String> strengths = <String>[];
    final List<String> improvements = <String>[];

    for (final EvaluationCriterionScore c in criteria) {
      final double pct = c.maxValue <= 0 ? 0 : c.value / c.maxValue;
      if (pct >= 0.7) {
        strengths.add('${c.label}: ${c.value.toStringAsFixed(1)}/${c.maxValue}');
      } else if (pct < 0.5) {
        improvements.add('${c.label}: ${c.value.toStringAsFixed(1)}/${c.maxValue}');
      }
    }

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
        criteria: criteria,
        criterionComments: Map<String, String>.from(score.criteriaComments),
        recommendation: rec,
        remarks: remarks,
        templateName: template.templateName,
      ),
      criteria: criteria,
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

class _CriterionAccumulator {
  const _CriterionAccumulator({
    required this.label,
    required this.maxValue,
    required this.sum,
    required this.count,
  });

  final String label;
  final int maxValue;
  final double sum;
  final int count;
}
