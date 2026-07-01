import '../../idea/models/enums/idea_status.dart';
import '../../idea/models/idea_model.dart';
import '../models/evaluation_recommendation_level.dart';
import '../../user/models/enums/judge_type.dart';
import '../../user/models/user_model.dart';
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
    required this.canShortlist,
    this.recommendation,
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
  final bool canShortlist;
  final EvaluationRecommendationLevel? recommendation;

  bool get hasEvaluations => judgeDetails.isNotEmpty;
}
