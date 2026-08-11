import '../../idea/models/idea_model.dart';
import '../../user/models/enums/judge_type.dart';
import '../../user/models/user_model.dart';
import '../services/evaluation_aggregation_service.dart';
import '../workspace/evaluation_workspace_loader.dart';

/// Lightweight judge row for the evaluation details workspace.
///
/// Full criteria are loaded on demand when the preview dialog opens.
class EvaluationJudgeDetail {
  const EvaluationJudgeDetail({
    required this.entry,
    required this.scoreId,
    required this.templateId,
    required this.judgeType,
    required this.scoringScale,
    this.judgeUser,
  });

  final EvaluationJudgeEntry entry;
  final String scoreId;
  final String templateId;
  final JudgeType? judgeType;
  final int scoringScale;
  final UserModel? judgeUser;
}

/// Evaluation-centric view model for the Evaluation Details workspace.
class EvaluationDetailsViewModel {
  const EvaluationDetailsViewModel({
    required this.ideaId,
    required this.idea,
    required this.ideaTitle,
    required this.problemTitle,
    required this.departmentName,
    required this.status,
    required this.statusLabel,
    required this.submittedByName,
    this.submittedByUser,
    required this.teamId,
    required this.teamName,
    required this.evaluationRank,
    required this.judgeDetails,
    required this.scoringScale,
    this.ideathonId = '',
    this.aggregateOverride,
  });

  final String ideaId;
  final IdeaModel idea;
  final String ideaTitle;
  final String problemTitle;
  final String departmentName;
  final IdeaStatus status;
  final String statusLabel;
  final String submittedByName;
  final UserModel? submittedByUser;
  final String teamId;
  final String teamName;
  final int? evaluationRank;
  final List<EvaluationJudgeDetail> judgeDetails;
  final int scoringScale;
  final String ideathonId;

  /// When set (e.g. Ideathon-scoped details), prefer over Idea aggregate fields.
  final IdeaEvaluationAggregate? aggregateOverride;

  bool get hasEvaluations => judgeDetails.isNotEmpty;
  bool get isIdeathonScoped => ideathonId.trim().isNotEmpty;
}
