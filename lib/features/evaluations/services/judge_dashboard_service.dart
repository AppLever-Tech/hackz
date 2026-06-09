import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../../../constants/app_icons.dart';
import '../assignments/services/evaluation_assignment_service.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../problems/models/problem_model.dart';
import '../models/score_model.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';

class JudgeDashboardService {
  JudgeDashboardService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<JudgeDashboardVm> load(UserModel judge) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: judge.orgId).get(),
    ]);

    final ideaDocs = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scoreDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final teamDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;

    final teamsById = <String, TeamModel>{
      for (final d in teamDocs) d.id: TeamModel.fromMap(d.id, d.data()),
    };
    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
    };
    final Set<String> assignedIdeaIds = await EvaluationAssignmentService.assignedIdeaIdsForJudge(
      orgId: judge.orgId,
      judgeId: judge.userId,
    );
    final scopedIdeas = ideaDocs
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .where((idea) => assignedIdeaIds.contains(idea.ideaId))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final scoresByJudge = scoreDocs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => s.judgeId == judge.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> scopedIdeaIds = scopedIdeas.map((i) => i.ideaId).toSet();
    final judgeScoresForAssigned =
        scoresByJudge.where((s) => scopedIdeaIds.contains(s.ideaId)).toList(growable: false);

    final scoresByIdea = <String, List<ScoreModel>>{};
    for (final score in judgeScoresForAssigned) {
      scoresByIdea.putIfAbsent(score.ideaId, () => <ScoreModel>[]).add(score);
    }
    for (final entry in scoresByIdea.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final evaluatedIdeaIds = scoresByIdea.keys.toSet();
    final pendingIdeas = scopedIdeas.where((i) => !evaluatedIdeaIds.contains(i.ideaId)).toList(growable: false);

    final latestScoreByIdea = <String, ScoreModel>{
      for (final entry in scoresByIdea.entries) entry.key: entry.value.first,
    };

    final evaluatedItems = latestScoreByIdea.entries
        .map((entry) => _toItem(scopedIdeas, teamsById, problemsById, entry.key, entry.value))
        .whereType<JudgeIdeaEvaluationItem>()
        .toList(growable: false)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final highestScored = List<JudgeIdeaEvaluationItem>.from(evaluatedItems)
      ..sort((a, b) => b.score.compareTo(a.score));

    final pendingItems = pendingIdeas
        .map((idea) => _toPendingItem(idea, teamsById, problemsById))
        .toList(growable: false)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final reevaluationItems = scoresByIdea.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => _toItem(scopedIdeas, teamsById, problemsById, entry.key, entry.value.first))
        .whereType<JudgeIdeaEvaluationItem>()
        .toList(growable: false)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    final avgScoreGiven = judgeScoresForAssigned.isEmpty
        ? null
        : judgeScoresForAssigned.map((s) => s.score).reduce((a, b) => a + b) / judgeScoresForAssigned.length;

    int lowScoreCount = 0;
    int mediumScoreCount = 0;
    int highScoreCount = 0;
    for (final score in judgeScoresForAssigned) {
      if (score.score < 4) {
        lowScoreCount++;
      } else if (score.score < 7) {
        mediumScoreCount++;
      } else {
        highScoreCount++;
      }
    }

    final activityItems = <JudgeActivityItem>[
      ...judgeScoresForAssigned.map(
        (s) => JudgeActivityItem(
          icon: AppIcons.statusEvaluated,
          text: 'Evaluation submitted (${s.score.toStringAsFixed(1)})',
          at: s.createdAt,
        ),
      ),
      ...judgeScoresForAssigned
          .where((s) => s.feedback.trim().isNotEmpty)
          .map(
            (s) => JudgeActivityItem(
              icon: AppIcons.scoring,
              text: 'Feedback added for idea ${s.ideaId}',
              at: s.createdAt,
            ),
          ),
      ...pendingIdeas.take(20).map(
            (idea) => JudgeActivityItem(
              icon: AppIcons.statusUnderEvaluation,
              text: 'Idea pending review: ${_ideaTitle(idea)}',
              at: idea.createdAt,
            ),
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return JudgeDashboardVm(
      assignedIdeas: scopedIdeas.length,
      evaluatedIdeas: evaluatedIdeaIds.length,
      pendingReviews: pendingIdeas.length,
      averageScoreGiven: avgScoreGiven,
      lowScoreCount: lowScoreCount,
      mediumScoreCount: mediumScoreCount,
      highScoreCount: highScoreCount,
      evaluationDates: judgeScoresForAssigned.map((ScoreModel s) => s.createdAt).toList(growable: false),
      recentEvaluatedIdeas: evaluatedItems.take(5).toList(growable: false),
      highestScoredIdeas: highestScored.take(5).toList(growable: false),
      pendingEvaluations: pendingItems.take(5).toList(growable: false),
      reevaluationIdeas: reevaluationItems.take(5).toList(growable: false),
      activities: activityItems.take(40).toList(growable: false),
    );
  }

  JudgeIdeaEvaluationItem? _toItem(
    List<IdeaModel> ideas,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
    String ideaId,
    ScoreModel score,
  ) {
    final idea = ideas.where((i) => i.ideaId == ideaId).cast<IdeaModel?>().firstWhere((i) => i != null, orElse: () => null);
    if (idea == null) return null;
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    return JudgeIdeaEvaluationItem(
      ideaId: idea.ideaId,
      title: _ideaTitle(idea),
      teamName: (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName,
      problemDepartment: (problem?.departmentDisplayName ?? idea.problemDepartmentCode).trim(),
      status: idea.status,
      score: score.score,
      lastUpdated: score.createdAt,
    );
  }

  JudgeIdeaEvaluationItem _toPendingItem(
    IdeaModel idea,
    Map<String, TeamModel> teamsById,
    Map<String, ProblemModel> problemsById,
  ) {
    final team = teamsById[idea.teamId];
    final problem = problemsById[idea.problemId];
    return JudgeIdeaEvaluationItem(
      ideaId: idea.ideaId,
      title: _ideaTitle(idea),
      teamName: (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName,
      problemDepartment: (problem?.departmentDisplayName ?? idea.problemDepartmentCode).trim(),
      status: idea.status,
      score: 0,
      lastUpdated: idea.createdAt,
    );
  }

  static String _ideaTitle(IdeaModel idea) {
    final title = idea.ideaTitle.trim();
    if (title.isNotEmpty) return title;
    if (idea.problemNumber.trim().isNotEmpty) return idea.problemNumber.trim();
    return idea.ideaId;
  }

}

class JudgeDashboardVm {
  const JudgeDashboardVm({
    required this.assignedIdeas,
    required this.evaluatedIdeas,
    required this.pendingReviews,
    required this.averageScoreGiven,
    required this.lowScoreCount,
    required this.mediumScoreCount,
    required this.highScoreCount,
    required this.evaluationDates,
    required this.recentEvaluatedIdeas,
    required this.highestScoredIdeas,
    required this.pendingEvaluations,
    required this.reevaluationIdeas,
    required this.activities,
  });

  final int assignedIdeas;
  final int evaluatedIdeas;
  final int pendingReviews;
  final double? averageScoreGiven;
  final int lowScoreCount;
  final int mediumScoreCount;
  final int highScoreCount;
  final List<DateTime> evaluationDates;
  final List<JudgeIdeaEvaluationItem> recentEvaluatedIdeas;
  final List<JudgeIdeaEvaluationItem> highestScoredIdeas;
  final List<JudgeIdeaEvaluationItem> pendingEvaluations;
  final List<JudgeIdeaEvaluationItem> reevaluationIdeas;
  final List<JudgeActivityItem> activities;
}

class JudgeIdeaEvaluationItem {
  const JudgeIdeaEvaluationItem({
    required this.ideaId,
    required this.title,
    required this.teamName,
    required this.problemDepartment,
    required this.status,
    required this.score,
    required this.lastUpdated,
  });

  final String ideaId;
  final String title;
  final String teamName;
  final String problemDepartment;
  final IdeaStatus status;
  final double score;
  final DateTime lastUpdated;
}

class JudgeActivityItem {
  const JudgeActivityItem({
    required this.icon,
    required this.text,
    required this.at,
  });

  final IconData icon;
  final String text;
  final DateTime at;
}
