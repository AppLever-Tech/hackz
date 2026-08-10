import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/evaluation_template.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../evaluations/services/evaluator_catalog_service.dart';
import '../../idea/models/idea_model.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../team/models/team_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import 'ideathon_service.dart';

/// One Ideathon idea row with event-scoped judge assignments.
class IdeathonJudgeAssignmentRow {
  const IdeathonJudgeAssignmentRow({
    required this.idea,
    required this.snapshot,
    required this.team,
    required this.assignments,
  });

  final IdeaModel idea;
  final IdeathonIdeaSnapshot snapshot;
  final TeamModel? team;
  final List<EvaluationAssignmentModel> assignments;

  String get ideaId => idea.ideaId;
  bool get isAssigned => assignments.isNotEmpty;
  List<String> get assignedJudgeIds =>
      assignments.map((EvaluationAssignmentModel a) => a.judgeId).toList(growable: false);
}

class IdeathonJudgeAssignmentMetrics {
  const IdeathonJudgeAssignmentMetrics({
    required this.totalIdeas,
    required this.assignedIdeas,
    required this.unassignedIdeas,
    required this.totalAssignments,
  });

  final int totalIdeas;
  final int assignedIdeas;
  final int unassignedIdeas;
  final int totalAssignments;
}

class IdeathonJudgeAssignmentViewModel {
  const IdeathonJudgeAssignmentViewModel({
    required this.ideathon,
    required this.template,
    required this.rows,
    required this.evaluators,
    required this.judgeById,
    required this.metrics,
  });

  final IdeathonModel ideathon;
  final EvaluationTemplate template;
  final List<IdeathonJudgeAssignmentRow> rows;
  final List<UserModel> evaluators;
  final Map<String, UserModel> judgeById;
  final IdeathonJudgeAssignmentMetrics metrics;
}

/// Loads and mutates Ideathon-scoped judge assignments (no evaluation scoring).
abstract final class IdeathonJudgeAssignmentService {
  IdeathonJudgeAssignmentService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool canManageAssignments(UserModel? actor) {
    if (actor == null) return false;
    return UserRole.fromCode(actor.role) == UserRole.departmentAdmin;
  }

  static Future<IdeathonJudgeAssignmentViewModel> load(String ideathonId) async {
    final IdeathonModel? ideathon = await IdeathonService.fetchById(ideathonId);
    if (ideathon == null) throw StateError('Ideathon not found.');

    await OrgSettingsService.instance.ensureLoaded(orgId: ideathon.orgId);
    final EvaluationTemplate template =
        EvaluationTemplatesService.resolveTemplate(ideathon.evaluationTemplateId);

    final List<String> ideaIds =
        ideathon.ideas.map((IdeathonIdeaSnapshot s) => s.ideaId.trim()).where((String id) => id.isNotEmpty).toList();
    final Map<String, IdeathonIdeaSnapshot> snapshotById = <String, IdeathonIdeaSnapshot>{
      for (final IdeathonIdeaSnapshot s in ideathon.ideas)
        if (s.ideaId.trim().isNotEmpty) s.ideaId.trim(): s,
    };

    final Map<String, IdeaModel> ideasById = await _loadIdeas(ideaIds);
    final Map<String, TeamModel> teamsById = await _loadTeams(ideasById.values);
    final List<EvaluationAssignmentModel> assignments =
        await EvaluationAssignmentService.listByIdeathon(ideathonId: ideathon.ideathonId);

    final Map<String, List<EvaluationAssignmentModel>> assignmentsByIdea =
        <String, List<EvaluationAssignmentModel>>{};
    final Set<String> judgeIds = <String>{...ideathon.judgeIds};
    for (final EvaluationAssignmentModel a in assignments) {
      if (a.ideaId.trim().isEmpty) continue;
      // Only Ideathon-registered ideas.
      if (!snapshotById.containsKey(a.ideaId.trim())) continue;
      assignmentsByIdea.putIfAbsent(a.ideaId.trim(), () => <EvaluationAssignmentModel>[]).add(a);
      if (a.judgeId.trim().isNotEmpty) judgeIds.add(a.judgeId.trim());
    }

    final List<UserModel> evaluators =
        await EvaluatorCatalogService.loadEvaluators(orgId: ideathon.orgId);
    final Map<String, UserModel> judgeById = <String, UserModel>{
      for (final UserModel u in evaluators) u.userId: u,
    };
    for (final String id in judgeIds) {
      if (judgeById.containsKey(id)) continue;
      final UserModel? user = await FirestoreUtils.fetchUser(id);
      if (user != null) judgeById[id] = user;
    }

    final List<IdeathonJudgeAssignmentRow> rows = <IdeathonJudgeAssignmentRow>[];
    for (final IdeathonIdeaSnapshot snapshot in ideathon.ideas) {
      final String ideaId = snapshot.ideaId.trim();
      if (ideaId.isEmpty) continue;
      final IdeaModel? idea = ideasById[ideaId];
      if (idea == null) continue;
      final List<EvaluationAssignmentModel> ideaAssignments =
          List<EvaluationAssignmentModel>.from(assignmentsByIdea[ideaId] ?? const <EvaluationAssignmentModel>[])
            ..sort((EvaluationAssignmentModel a, EvaluationAssignmentModel b) =>
                a.judgeId.compareTo(b.judgeId));
      rows.add(
        IdeathonJudgeAssignmentRow(
          idea: idea,
          snapshot: snapshot,
          team: teamsById[idea.teamId.trim()],
          assignments: ideaAssignments,
        ),
      );
    }
    rows.sort((IdeathonJudgeAssignmentRow a, IdeathonJudgeAssignmentRow b) =>
        a.snapshot.ideaTitle.compareTo(b.snapshot.ideaTitle));

    final int assignedIdeas = rows.where((IdeathonJudgeAssignmentRow r) => r.isAssigned).length;
    return IdeathonJudgeAssignmentViewModel(
      ideathon: ideathon,
      template: template,
      rows: rows,
      evaluators: evaluators,
      judgeById: judgeById,
      metrics: IdeathonJudgeAssignmentMetrics(
        totalIdeas: rows.length,
        assignedIdeas: assignedIdeas,
        unassignedIdeas: rows.length - assignedIdeas,
        totalAssignments: assignments
            .where((EvaluationAssignmentModel a) => snapshotById.containsKey(a.ideaId.trim()))
            .length,
      ),
    );
  }

  static Future<void> assignJudgesToIdea({
    required UserModel actor,
    required String ideathonId,
    required String ideaId,
    required Iterable<String> judgeIds,
  }) async {
    if (!canManageAssignments(actor)) {
      throw StateError('Only Department Admin can assign Ideathon judges.');
    }
    final IdeathonModel? ideathon = await IdeathonService.fetchById(ideathonId);
    if (ideathon == null) throw StateError('Ideathon not found.');

    final String targetIdeaId = ideaId.trim();
    final bool onEvent = ideathon.ideas.any(
      (IdeathonIdeaSnapshot s) => s.ideaId.trim() == targetIdeaId,
    );
    if (!onEvent) {
      throw StateError('Idea is not registered for this Ideathon.');
    }

    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(targetIdeaId).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Idea not found.');
    }
    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);

    final List<UserModel> judges = <UserModel>[];
    for (final String raw in judgeIds) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      final UserModel? user = await FirestoreUtils.fetchUser(id);
      if (user != null) judges.add(user);
    }
    if (judges.isEmpty) throw StateError('Select at least one judge.');

    TeamModel? team;
    final String teamId = idea.teamId.trim();
    if (teamId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> teamDoc =
          await _db.collection(FirestoreUtils.hkzTeams).doc(teamId).get();
      if (teamDoc.exists && teamDoc.data() != null) {
        team = TeamModel.fromMap(teamDoc.id, teamDoc.data()!);
      }
    }

    await EvaluationAssignmentService.assignIdeasToJudgesForIdeathon(
      orgId: ideathon.orgId,
      actorUserId: actor.userId,
      ideathonId: ideathon.ideathonId,
      ideas: <IdeaModel>[idea],
      judges: judges,
      teamsById: team == null ? const <String, TeamModel>{} : <String, TeamModel>{team.teamId: team},
    );

    await _ensureJudgesOnIdeathonRoster(
      ideathon: ideathon,
      judgeIds: judges.map((UserModel j) => j.userId),
    );
  }

  static Future<void> removeAssignment({
    required UserModel actor,
    required String ideathonId,
    required String assignmentId,
  }) async {
    if (!canManageAssignments(actor)) {
      throw StateError('Only Department Admin can reassign Ideathon judges.');
    }
    await EvaluationAssignmentService.removeIdeathonAssignment(
      assignmentId: assignmentId,
      ideathonId: ideathonId,
    );
  }

  static Future<Map<String, IdeaModel>> _loadIdeas(List<String> ideaIds) async {
    final Map<String, IdeaModel> byId = <String, IdeaModel>{};
    for (final String id in ideaIds) {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
      if (!doc.exists || doc.data() == null) continue;
      byId[id] = IdeaModel.fromMap(doc.id, doc.data()!);
    }
    return byId;
  }

  static Future<Map<String, TeamModel>> _loadTeams(Iterable<IdeaModel> ideas) async {
    final Map<String, TeamModel> byId = <String, TeamModel>{};
    for (final IdeaModel idea in ideas) {
      final String teamId = idea.teamId.trim();
      if (teamId.isEmpty || byId.containsKey(teamId)) continue;
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(FirestoreUtils.hkzTeams).doc(teamId).get();
      if (!doc.exists || doc.data() == null) continue;
      byId[teamId] = TeamModel.fromMap(doc.id, doc.data()!);
    }
    return byId;
  }

  static Future<void> _ensureJudgesOnIdeathonRoster({
    required IdeathonModel ideathon,
    required Iterable<String> judgeIds,
  }) async {
    final Set<String> next = ideathon.judgeIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toSet();
    final int before = next.length;
    next.addAll(judgeIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty));
    if (next.length == before) return;
    final List<String> sorted = next.toList()..sort();
    await _db.collection(FirestoreUtils.hkzIdeathons).doc(ideathon.ideathonId).update(<String, dynamic>{
      'judgeIds': sorted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String judgeDisplayName(Map<String, UserModel> judgeById, String judgeId) {
    final UserModel? user = judgeById[judgeId.trim()];
    if (user == null) return judgeId;
    return userDisplayName(user);
  }
}
