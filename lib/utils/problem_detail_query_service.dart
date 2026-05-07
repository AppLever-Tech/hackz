import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/department_model.dart';
import '../models/enums/user_role.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/score_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';
import 'idea_query_service.dart';
import 'problem_detail_config.dart';

class ProblemIdeaAggregate {
  const ProblemIdeaAggregate({
    required this.item,
    required this.avgScore,
    required this.scoreCount,
    required this.studentCount,
    required this.mentorId,
  });

  final IdeaListItem item;
  final double? avgScore;
  final int scoreCount;
  final int studentCount;
  final String mentorId;

  bool get hasScore => scoreCount > 0;
}

class ProblemDetailQueryService {
  ProblemDetailQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<ProblemIdeaAggregate>> fetchIdeasForProblem({
    required String problemId,
    required String orgId,
    required ProblemDetailConfig config,
    required UserModel currentUser,
    int limit = 500,
  }) async {
    Query<Map<String, dynamic>> ideasQuery = _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: orgId)
        .where('problemId', isEqualTo: problemId)
        .limit(limit);

    final viewerDepartment = DepartmentModel.resolveCode(currentUser.departmentCode);
    final shouldRestrictToDepartment = config.restrictToDepartment && viewerDepartment.isNotEmpty;
    if (shouldRestrictToDepartment &&
        (config.ideaScope == ProblemIdeaScope.department || config.ideaScope == ProblemIdeaScope.teamOwn)) {
      ideasQuery = ideasQuery.where('departmentCode', isEqualTo: viewerDepartment);
    }

    final ideasSnap = await ideasQuery.get();
    var ideas = ideasSnap.docs
        .map((doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    if (ideas.isEmpty) return const <ProblemIdeaAggregate>[];

    final teamsById = await _fetchTeamsById(orgId: orgId, teamIds: ideas.map((e) => e.teamId));
    ideas = _applyScopeFilter(
      ideas: ideas,
      teamsById: teamsById,
      config: config,
      currentUser: currentUser,
      viewerDepartment: viewerDepartment,
    );
    if (ideas.isEmpty) return const <ProblemIdeaAggregate>[];

    final ideaIds = ideas.map((e) => e.ideaId).toSet();
    final filteredTeamsById = await _fetchTeamsById(
      orgId: orgId,
      teamIds: ideas.map((idea) => idea.teamId),
    );
    final paymentByIdeaId = await _fetchPaymentsByIdeaId(orgId: orgId, ideaIds: ideaIds);
    final scoresByIdeaId = await _fetchScoresByIdeaId(orgId: orgId, ideaIds: ideaIds);

    final aggregates = <ProblemIdeaAggregate>[];
    for (final idea in ideas) {
      final team = filteredTeamsById[idea.teamId];
      final scoreSet = scoresByIdeaId[idea.ideaId] ?? const <ScoreModel>[];
      final avgScore = scoreSet.isEmpty
          ? null
          : scoreSet.map((e) => e.score).reduce((a, b) => a + b) / scoreSet.length;
      final latestScore = scoreSet.isEmpty
          ? null
          : (ScoreModel(
              scoreId: '',
              ideaId: idea.ideaId,
              judgeId: 'AGG',
              score: avgScore!,
              feedback: '',
              createdAt: DateTime.now(),
              orgId: orgId,
              departmentCode: idea.departmentCode,
            ));
      final canUploadPayment = _viewerCanUploadPayment(
        currentUser: currentUser,
        idea: idea,
        team: team,
        payment: paymentByIdeaId[idea.ideaId],
      );
      final item = IdeaListItem(
        idea: idea,
        teamName: (team?.teamName ?? '').trim().isEmpty ? idea.teamId : team!.teamName.trim(),
        team: team,
        payment: paymentByIdeaId[idea.ideaId],
        score: latestScore,
        canUploadPayment: canUploadPayment,
      );
      aggregates.add(
        ProblemIdeaAggregate(
          item: item,
          avgScore: avgScore,
          scoreCount: scoreSet.length,
          studentCount: team?.studentIds.length ?? 0,
          mentorId: team?.mentorId ?? '',
        ),
      );
    }
    aggregates.sort((a, b) => b.item.idea.createdAt.compareTo(a.item.idea.createdAt));
    return aggregates;
  }

  static List<IdeaModel> _applyScopeFilter({
    required List<IdeaModel> ideas,
    required Map<String, TeamModel> teamsById,
    required ProblemDetailConfig config,
    required UserModel currentUser,
    required String viewerDepartment,
  }) {
    final userId = currentUser.userId.trim();
    return ideas.where((idea) {
      if (config.restrictToDepartment &&
          viewerDepartment.isNotEmpty &&
          config.ideaScope == ProblemIdeaScope.department &&
          DepartmentModel.resolveCode(idea.departmentCode) != viewerDepartment) {
        return false;
      }
      final team = teamsById[idea.teamId];
      switch (config.ideaScope) {
        case ProblemIdeaScope.facultyOwn:
          return idea.createdBy.trim() == userId || (team?.mentorId.trim() ?? '') == userId;
        case ProblemIdeaScope.teamOwn:
          return team?.studentIds.contains(userId) ?? false;
        case ProblemIdeaScope.department:
          return viewerDepartment.isEmpty ||
              DepartmentModel.resolveCode(idea.departmentCode) == viewerDepartment;
        case ProblemIdeaScope.org:
          return true;
      }
    }).toList(growable: false);
  }

  static Future<Map<String, TeamModel>> _fetchTeamsById({
    required String orgId,
    required Iterable<String> teamIds,
  }) async {
    final ids = teamIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return <String, TeamModel>{};
    final snap = await _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: orgId).get();
    final out = <String, TeamModel>{};
    for (final doc in snap.docs) {
      final team = TeamModel.fromMap(doc.id, doc.data());
      if (ids.contains(team.teamId)) out[team.teamId] = team;
    }
    return out;
  }

  static Future<Map<String, PaymentModel>> _fetchPaymentsByIdeaId({
    required String orgId,
    required Set<String> ideaIds,
  }) async {
    if (ideaIds.isEmpty) return <String, PaymentModel>{};
    final snap = await _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).get();
    final out = <String, PaymentModel>{};
    for (final doc in snap.docs) {
      final model = PaymentModel.fromMap(doc.id, doc.data());
      if (ideaIds.contains(model.ideaId)) out[model.ideaId] = model;
    }
    return out;
  }

  static Future<Map<String, List<ScoreModel>>> _fetchScoresByIdeaId({
    required String orgId,
    required Set<String> ideaIds,
  }) async {
    if (ideaIds.isEmpty) return <String, List<ScoreModel>>{};
    final snap = await _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).get();
    final out = <String, List<ScoreModel>>{};
    for (final doc in snap.docs) {
      final score = ScoreModel.fromMap(doc.id, doc.data());
      if (!ideaIds.contains(score.ideaId)) continue;
      out.putIfAbsent(score.ideaId, () => <ScoreModel>[]).add(score);
    }
    return out;
  }

  static bool _viewerCanUploadPayment({
    required UserModel currentUser,
    required IdeaModel idea,
    required TeamModel? team,
    required PaymentModel? payment,
  }) {
    if (idea.status != IdeaStatus.pendingSubmission) return false;
    if (payment != null && payment.status != PaymentRecordStatus.rejected) return false;
    if (team == null) return false;
    final role = UserRole.fromCode(currentUser.role);
    if (role == UserRole.student) return team.studentIds.contains(currentUser.userId);
    if (role == UserRole.faculty) return team.mentorId == currentUser.userId;
    return false;
  }
}
