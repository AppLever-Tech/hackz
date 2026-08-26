import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums/team_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../problems/models/problem_model.dart';
import '../models/team_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import 'team_service.dart';

class TeamWorkspaceInsight {
  const TeamWorkspaceInsight({
    required this.team,
    required this.ideas,
    required this.paymentStatuses,
    required this.evaluationCount,
  });

  final TeamModel team;
  final List<IdeaModel> ideas;
  final List<PaymentRecordStatus> paymentStatuses;
  final int evaluationCount;

  int get submittedIdeas => ideas.where((idea) => idea.status != IdeaStatus.draft).length;
  bool get hasIdeas => ideas.isNotEmpty;
  bool get hasPendingPayment => paymentStatuses.any((status) => status == PaymentRecordStatus.pending);
  bool get hasEvaluation => evaluationCount > 0 || ideas.any((idea) => idea.hasEvaluationAggregate);
  bool get isLocked => team.status == TeamStatus.locked || hasIdeas;
}

class TeamsWorkspaceData {
  const TeamsWorkspaceData({
    required this.teams,
    required this.teamMembers,
    required this.memberNamesById,
    required this.insightsByTeamId,
    required this.problems,
  });

  final List<TeamModel> teams;
  final List<UserModel> teamMembers;
  final Map<String, String> memberNamesById;
  final Map<String, TeamWorkspaceInsight> insightsByTeamId;
  final List<ProblemModel> problems;

  int get totalTeamMembers => teams.expand((team) => team.studentIds).toSet().length;
  int get activeIdeas => insightsByTeamId.values.fold<int>(0, (sum, insight) => sum + insight.ideas.length);
}

class TeamsWorkspaceService {
  TeamsWorkspaceService._();

  static const int maxTeamsPerLeader = 1;
  static const int minMembersPerTeam = 2;
  static const int maxMembersPerTeam = 4;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, TeamsWorkspaceData> _cache = <String, TeamsWorkspaceData>{};
  static final Map<String, DateTime> _cacheAt = <String, DateTime>{};
  static const Duration _cacheTtl = Duration(minutes: 3);

  static void clearCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  static void _invalidate(String actorId) {
    _cache.remove(actorId);
    _cacheAt.remove(actorId);
  }

  static Future<TeamsWorkspaceData> load(UserModel actor, {bool forceRefresh = false}) async {
    final cached = _cache[actor.userId];
    final cachedAt = _cacheAt[actor.userId];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      TeamService.getTeamsLedBy(actor.userId),
      TeamService.getDepartmentTeamMembers(orgId: actor.orgId, departmentCode: actor.departmentCode),
      TeamService.getDepartmentProblems(orgId: actor.orgId, departmentCode: actor.departmentCode),
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: actor.orgId).get(),
      _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: actor.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: actor.orgId).get(),
    ]);

    final teams = results[0] as List<TeamModel>;
    final teamMembers = sortUsersByDisplayName(results[1] as List<UserModel>);
    final problems = results[2] as List<ProblemModel>;
    final teamIds = teams.map((team) => team.teamId).toSet();
    final ideas = (results[3] as QuerySnapshot<Map<String, dynamic>>)
        .docs
        .map((doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .where((idea) => teamIds.contains(idea.teamId))
        .toList(growable: false);
    final payments = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scores = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;

    final ideasByTeam = <String, List<IdeaModel>>{};
    for (final idea in ideas) {
      ideasByTeam.putIfAbsent(idea.teamId, () => <IdeaModel>[]).add(idea);
    }

    final paymentsByIdea = <String, PaymentRecordStatus>{};
    for (final payment in payments) {
      final data = payment.data();
      final ideaId = ((data['ideaId'] as String?) ?? payment.id).trim();
      if (ideaId.isEmpty) continue;
      paymentsByIdea[ideaId] = PaymentRecordStatus.fromRaw((data['status'] as String?) ?? '');
    }

    final scoresByIdea = <String, int>{};
    for (final score in scores) {
      final ideaId = ((score.data()['ideaId'] as String?) ?? '').trim();
      if (ideaId.isEmpty) continue;
      scoresByIdea[ideaId] = (scoresByIdea[ideaId] ?? 0) + 1;
    }

    final insights = <String, TeamWorkspaceInsight>{};
    for (final team in teams) {
      final teamIdeas = ideasByTeam[team.teamId] ?? const <IdeaModel>[];
      insights[team.teamId] = TeamWorkspaceInsight(
        team: team,
        ideas: teamIdeas,
        paymentStatuses: teamIdeas
            .map((idea) => paymentsByIdea[idea.ideaId])
            .whereType<PaymentRecordStatus>()
            .toList(growable: false),
        evaluationCount: teamIdeas.fold<int>(0, (sum, idea) => sum + (scoresByIdea[idea.ideaId] ?? 0)),
      );
    }

    final data = TeamsWorkspaceData(
      teams: teams,
      teamMembers: teamMembers,
      memberNamesById: <String, String>{for (final member in teamMembers) member.userId: userDisplayName(member)},
      insightsByTeamId: insights,
      problems: problems,
    );
    _cache[actor.userId] = data;
    _cacheAt[actor.userId] = DateTime.now();
    return data;
  }

  static int maxTeamsFor(UserModel actor) => maxTeamsPerLeader;

  static bool canCreateTeam(List<TeamModel> existingTeams, {UserModel? actor}) {
    if (actor != null && UserRole.fromCode(actor.role) == UserRole.departmentAdmin) {
      return true;
    }
    final int max = actor == null ? maxTeamsPerLeader : maxTeamsFor(actor);
    return existingTeams.length < max;
  }

  static Future<void> saveTeam({
    required UserModel actor,
    required String teamName,
    required Set<String> studentIds,
    required String teamLeaderId,
    required List<TeamModel> existingTeams,
    required List<UserModel> departmentTeamMembers,
    TeamModel? editingTeam,
  }) async {
    await TeamService.validateTeamUpsert(
      actor: actor,
      teamName: teamName,
      selectedMemberIds: studentIds,
      teamLeaderId: teamLeaderId,
      existingTeams: existingTeams,
      departmentTeamMembers: departmentTeamMembers,
      editingTeam: editingTeam,
    );
    if (editingTeam == null) {
      await TeamService.createTeam(
        actor: actor,
        teamName: teamName,
        studentIds: studentIds,
        teamLeaderId: teamLeaderId,
      );
    } else {
      await TeamService.updateTeam(
        team: editingTeam,
        teamName: teamName,
        studentIds: studentIds,
        teamLeaderId: teamLeaderId,
      );
    }
    _invalidate(actor.userId);
  }

  static Future<void> disableTeam(TeamModel team, {required UserModel actor}) async {
    TeamService.assertCanManageTeam(actor, team);
    final batch = _db.batch();
    batch.set(
      _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId),
      <String, dynamic>{'status': TeamStatus.inactive.value},
      SetOptions(merge: true),
    );
    for (final memberId in team.studentIds) {
      batch.set(_db.collection(FirestoreUtils.hkzUsers).doc(memberId), <String, dynamic>{'teamId': null}, SetOptions(merge: true));
    }
    await batch.commit();
    clearCache();
  }
}
