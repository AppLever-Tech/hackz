import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_icons.dart';
import '../models/idea_model.dart';
import '../features/problems/models/problem_model.dart';
import '../models/score_model.dart';
import '../features/team/models/team_model.dart';
import '../models/user_model.dart';
import 'common_helpers.dart';
import 'firestore_utils.dart';
import 'role_visibility_helpers.dart';

class JudgeDashboardService {
  JudgeDashboardService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<JudgeDashboardVm> load(UserModel judge) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: judge.orgId).get(),
      _db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: judge.orgId).get(),
    ]);

    final ideaDocs = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scoreDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final teamDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final userDocs = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;

    final teamsById = <String, TeamModel>{
      for (final d in teamDocs) d.id: TeamModel.fromMap(d.id, d.data()),
    };
    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
    };
    final usersById = <String, UserModel>{
      for (final d in userDocs)
        (UserModel.fromMap(d.data()).userId.trim().isEmpty ? d.id : UserModel.fromMap(d.data()).userId.trim()):
            UserModel.fromMap(d.data()),
    };

    final scopedIdeas = ideaDocs
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .where((idea) => RoleVisibilityHelpers.ideaVisibleToUser(idea, judge))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final scoresByJudge = scoreDocs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => s.judgeId == judge.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final assignedIdeaIds = scopedIdeas.map((i) => i.ideaId).toSet();
    final judgeScoresForAssigned = scoresByJudge.where((s) => assignedIdeaIds.contains(s.ideaId)).toList(growable: false);

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

    final evaluationTimeline = <String, int>{};
    for (final score in judgeScoresForAssigned) {
      final day = _formatDayKey(score.createdAt);
      evaluationTimeline[day] = (evaluationTimeline[day] ?? 0) + 1;
    }
    final sortedTimeline = <String, int>{};
    final sortedKeys = evaluationTimeline.keys.toList()..sort();
    for (final key in sortedKeys) {
      sortedTimeline[key] = evaluationTimeline[key] ?? 0;
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
              icon: AppIcons.statusUnderReview,
              text: 'Idea pending review: ${_ideaTitle(idea)}',
              at: idea.createdAt,
            ),
          ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final judgeName = _fullName(judge);
    final companyOrOrg = judge.orgId;
    final expertise = judge.department.isEmpty ? judge.departmentCode : judge.department;
    final assignedDepartments = scopedIdeas
        .map((i) => problemsById[i.problemId]?.departmentDisplayName ?? i.problemDepartmentCode)
        .where((d) => d.trim().isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final avgTurnaroundHours = _computeAverageTurnaroundHours(allIdeas: scopedIdeas, judgedItems: evaluatedItems);

    return JudgeDashboardVm(
      judgeName: judgeName,
      organizationName: companyOrOrg,
      expertise: expertise,
      assignedDepartments: assignedDepartments,
      assignedIdeas: scopedIdeas.length,
      evaluatedIdeas: evaluatedIdeaIds.length,
      pendingReviews: pendingIdeas.length,
      averageScoreGiven: avgScoreGiven,
      avgTurnaroundHours: avgTurnaroundHours,
      pendingDistributionCount: pendingIdeas.length,
      completedDistributionCount: evaluatedIdeaIds.length,
      lowScoreCount: lowScoreCount,
      mediumScoreCount: mediumScoreCount,
      highScoreCount: highScoreCount,
      evaluationTimeline: sortedTimeline,
      recentEvaluatedIdeas: evaluatedItems.take(5).toList(growable: false),
      highestScoredIdeas: highestScored.take(5).toList(growable: false),
      pendingEvaluations: pendingItems.take(5).toList(growable: false),
      reevaluationIdeas: reevaluationItems.take(5).toList(growable: false),
      activities: activityItems.take(40).toList(growable: false),
      judgeEmail: judge.email,
      judgePhone: judge.phone,
      usersById: usersById,
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

  static String _fullName(UserModel user) {
    final full = '${user.firstName} ${user.lastName}'.trim();
    return full.isEmpty ? user.userId : full;
  }

  static double? _computeAverageTurnaroundHours({
    required List<IdeaModel> allIdeas,
    required List<JudgeIdeaEvaluationItem> judgedItems,
  }) {
    if (judgedItems.isEmpty) return null;
    final mapById = <String, IdeaModel>{for (final i in allIdeas) i.ideaId: i};
    final durations = <double>[];
    for (final item in judgedItems) {
      final source = mapById[item.ideaId];
      if (source == null) continue;
      final diff = item.lastUpdated.difference(source.createdAt).inMinutes;
      if (diff > 0) durations.add(diff / 60);
    }
    if (durations.isEmpty) return null;
    final sum = durations.reduce((a, b) => a + b);
    return sum / durations.length;
  }

  static String _formatDayKey(DateTime date) {
    final full = formatDateTime(date);
    final parts = full.split(' ');
    return parts.isEmpty ? full : parts.first;
  }
}

class JudgeDashboardVm {
  const JudgeDashboardVm({
    required this.judgeName,
    required this.organizationName,
    required this.expertise,
    required this.assignedDepartments,
    required this.assignedIdeas,
    required this.evaluatedIdeas,
    required this.pendingReviews,
    required this.averageScoreGiven,
    required this.avgTurnaroundHours,
    required this.pendingDistributionCount,
    required this.completedDistributionCount,
    required this.lowScoreCount,
    required this.mediumScoreCount,
    required this.highScoreCount,
    required this.evaluationTimeline,
    required this.recentEvaluatedIdeas,
    required this.highestScoredIdeas,
    required this.pendingEvaluations,
    required this.reevaluationIdeas,
    required this.activities,
    required this.judgeEmail,
    required this.judgePhone,
    required this.usersById,
  });

  final String judgeName;
  final String organizationName;
  final String expertise;
  final List<String> assignedDepartments;
  final int assignedIdeas;
  final int evaluatedIdeas;
  final int pendingReviews;
  final double? averageScoreGiven;
  final double? avgTurnaroundHours;
  final int pendingDistributionCount;
  final int completedDistributionCount;
  final int lowScoreCount;
  final int mediumScoreCount;
  final int highScoreCount;
  final Map<String, int> evaluationTimeline;
  final List<JudgeIdeaEvaluationItem> recentEvaluatedIdeas;
  final List<JudgeIdeaEvaluationItem> highestScoredIdeas;
  final List<JudgeIdeaEvaluationItem> pendingEvaluations;
  final List<JudgeIdeaEvaluationItem> reevaluationIdeas;
  final List<JudgeActivityItem> activities;
  final String judgeEmail;
  final String judgePhone;
  final Map<String, UserModel> usersById;
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
