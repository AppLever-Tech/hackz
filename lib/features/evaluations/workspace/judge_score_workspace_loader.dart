import '../../ideathons/models/ideathon_model.dart';
import '../../ideathons/services/ideathon_service.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../organization/models/organization_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';
import '../models/score_model.dart';
import '../services/evaluation_template_helpers.dart';
import '../services/evaluation_templates_service.dart';
import '../services/judge_evaluation_feedback_codec.dart';
import 'evaluation_workspace_loader.dart';

class JudgeScoreCriterionView {
  const JudgeScoreCriterionView({
    required this.criterion,
    required this.value,
    required this.weightLabel,
    this.comment = '',
  });

  final EvaluationCriterion criterion;
  final int value;
  final String weightLabel;
  final String comment;
}

class JudgeScoreWorkspaceViewModel {
  const JudgeScoreWorkspaceViewModel({
    required this.judge,
    required this.idea,
    required this.teamLabel,
    required this.score,
    required this.template,
    required this.criteria,
    this.event,
    this.organisationName = '',
  });

  final UserModel judge;
  final IdeaModel idea;
  final String teamLabel;
  final ScoreModel score;
  final EvaluationTemplate template;
  final List<JudgeScoreCriterionView> criteria;
  final IdeathonModel? event;
  final String organisationName;

  int get criteriaCount => criteria.length;

  String get weightageLabel =>
      '${EvaluationTemplateHelpers.totalWeightPercentRounded(template.criteria)}%';

  String get templateLabel {
    final String name = template.templateName.trim();
    if (name.isNotEmpty) return name;
    final String id = template.templateId.trim();
    return id.isEmpty ? 'Evaluation template' : id;
  }
}

abstract final class JudgeScoreWorkspaceLoader {
  static Future<JudgeScoreWorkspaceViewModel> load({
    required String scoreId,
    required IdeaModel idea,
    required String teamLabel,
    required String templateId,
    required String ideathonId,
    required String departmentCode,
    UserModel? judge,
  }) async {
    final EvaluationJudgeCriteriaDetail loaded =
        await EvaluationWorkspaceLoader.loadJudgeCriteriaDetail(
      scoreId,
      departmentCode: departmentCode,
    );
    final UserModel? scoringJudge =
        judge ?? await FirestoreUtils.fetchUser(loaded.score.judgeId.trim());
    if (scoringJudge == null) {
      throw StateError('This judge profile could not be loaded.');
    }

    String eventId = ideathonId.trim();
    if (eventId.isEmpty) eventId = loaded.score.ideathonId.trim();

    EvaluationTemplate template = loaded.template;
    String forcedTemplateId = templateId.trim();
    IdeathonModel? event;
    String organisationName = '';
    if (eventId.isNotEmpty) {
      event = await IdeathonService.fetchById(eventId);
      if (event != null) {
        final String eventTemplateId = event.evaluationTemplateId.trim().isNotEmpty
            ? event.evaluationTemplateId.trim()
            : (forcedTemplateId.isNotEmpty ? forcedTemplateId : loaded.score.templateId);
        template = EvaluationTemplatesService.resolveForEvent(
          templateId: eventTemplateId,
          departmentCode: event.departmentId,
          eventCriteria: event.evaluationCriteria,
        );
        if (event.orgId.trim().isNotEmpty) {
          final OrganizationModel? org = await FirestoreUtils.fetchOrganization(event.orgId);
          organisationName = (org?.name ?? '').trim();
        }
      }
    }

    return JudgeScoreWorkspaceViewModel(
      judge: scoringJudge,
      idea: idea,
      teamLabel: teamLabel,
      score: loaded.score,
      template: template,
      criteria: _criteriaFor(loaded.score, template),
      event: event,
      organisationName: organisationName,
    );
  }

  static List<JudgeScoreCriterionView> _criteriaFor(
    ScoreModel score,
    EvaluationTemplate template,
  ) {
    final JudgeEvaluationDecodedFeedback? legacy =
        JudgeEvaluationFeedbackCodec.tryDecode(score.feedback);
    final List<JudgeScoreCriterionView> rows = <JudgeScoreCriterionView>[];
    for (final EvaluationCriterion c in template.orderedCriteria) {
      int? seed;
      final double? saved = score.criteriaScores[c.criterionId];
      if (saved != null) {
        seed = saved.round().clamp(c.minScore, c.maxScore);
      } else if (legacy != null) {
        switch (c.criterionId) {
          case 'innovation':
            seed = legacy.innovation.clamp(c.minScore, c.maxScore);
            break;
          case 'feasibility':
            seed = legacy.feasibility.clamp(c.minScore, c.maxScore);
            break;
          case 'impact':
            seed = legacy.impact.clamp(c.minScore, c.maxScore);
            break;
        }
      }
      rows.add(
        JudgeScoreCriterionView(
          criterion: c,
          value: seed ?? ((c.minScore + c.maxScore) ~/ 2),
          weightLabel: EvaluationTemplateHelpers.weightLabel(c, template),
          comment: (score.criteriaComments[c.criterionId] ?? '').trim(),
        ),
      );
    }
    return rows;
  }
}
