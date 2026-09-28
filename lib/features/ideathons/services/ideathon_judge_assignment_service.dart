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
import 'event_details_evaluation_access.dart';
import 'event_details_evaluation_bundle.dart';
import 'event_details_tab_cache.dart';
import 'ideathon_details_loader.dart';
import 'ideathon_details_shell_loader.dart';
import 'ideathon_service.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

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

class IdeathonJudgeWorkload {
  const IdeathonJudgeWorkload({
    required this.judgeId,
    required this.displayName,
    required this.ideaCount,
  });

  final String judgeId;
  final String displayName;
  final int ideaCount;
}

class IdeathonJudgeAssignmentViewModel {
  const IdeathonJudgeAssignmentViewModel({
    required this.ideathon,
    required this.template,
    required this.rows,
    required this.evaluators,
    required this.judgeById,
    required this.metrics,
    required this.workloads,
    this.evaluationLocked = false,
  });

  final IdeathonModel ideathon;
  final EvaluationTemplate template;
  final List<IdeathonJudgeAssignmentRow> rows;
  final List<UserModel> evaluators;
  final Map<String, UserModel> judgeById;
  final IdeathonJudgeAssignmentMetrics metrics;
  final List<IdeathonJudgeWorkload> workloads;
  final bool evaluationLocked;
}

/// Loads and mutates Ideathon-scoped judge assignments (no evaluation scoring).
abstract final class IdeathonJudgeAssignmentService {
  IdeathonJudgeAssignmentService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static bool canManageAssignments(UserModel? actor) {
    if (actor == null) return false;
    return UserRole.fromCode(actor.role) == UserRole.departmentAdmin;
  }

  /// Event Details tab: reuse cached evaluation bundle (ideas + assignments).
  static Future<IdeathonJudgeAssignmentViewModel> loadForEventDetails(
    IdeathonDetailsShellViewModel shell,
    EventDetailsTabCacheBucket cache,
  ) async {
    final EventDetailsEvaluationBundle bundle = await EventDetailsEvaluationAccess.bundle(cache, shell);
    final Map<String, IdeaModel> ideasById = <String, IdeaModel>{
      for (final IdeathonIdeaEntry entry in bundle.ideaEntries)
        if (entry.idea != null && entry.ideaId.trim().isNotEmpty) entry.ideaId.trim(): entry.idea!,
    };
    return _loadFromParts(
      ideathon: shell.ideathon,
      ideasById: ideasById,
      assignments: bundle.assignments,
    );
  }

  static Future<IdeathonJudgeAssignmentViewModel> load(String ideathonId) async {
    final String id = ideathonId.trim();
    final List<dynamic> head = await Future.wait<dynamic>(<Future<dynamic>>[
      IdeathonService.fetchById(id),
      EvaluationAssignmentService.listByIdeathon(ideathonId: id),
    ]);
    final IdeathonModel? ideathon = head[0] as IdeathonModel?;
    if (ideathon == null) throw StateError('Ideathon not found.');
    final List<EvaluationAssignmentModel> assignments = head[1] as List<EvaluationAssignmentModel>;
    final List<String> ideaIds = ideathon.ideas
        .map((IdeathonIdeaSnapshot s) => s.ideaId.trim())
        .where((String ideaId) => ideaId.isNotEmpty)
        .toList(growable: false);
    final Map<String, IdeaModel> ideasById = await EvaluationResultsQueryService.loadIdeasByIds(ideaIds);
    return _loadFromParts(
      ideathon: ideathon,
      ideasById: ideasById,
      assignments: assignments,
    );
  }

  static Future<IdeathonJudgeAssignmentViewModel> _loadFromParts({
    required IdeathonModel ideathon,
    required Map<String, IdeaModel> ideasById,
    required List<EvaluationAssignmentModel> assignments,
  }) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: ideathon.orgId);
    final EvaluationTemplate template =
        EvaluationTemplatesService.resolveTemplate(ideathon.evaluationTemplateId);

    final Map<String, IdeathonIdeaSnapshot> snapshotById = <String, IdeathonIdeaSnapshot>{
      for (final IdeathonIdeaSnapshot s in ideathon.ideas)
        if (s.ideaId.trim().isNotEmpty) s.ideaId.trim(): s,
    };

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      _loadTeams(ideasById.values),
      EvaluatorCatalogService.loadEvaluators(orgId: ideathon.orgId),
      _evaluationLocked(ideathon),
    ]);
    final Map<String, TeamModel> teamsById = parallel[0] as Map<String, TeamModel>;
    final List<UserModel> evaluators = parallel[1] as List<UserModel>;
    final bool evaluationLocked = parallel[2] as bool;

    final Map<String, List<EvaluationAssignmentModel>> assignmentsByIdea =
        <String, List<EvaluationAssignmentModel>>{};
    final Set<String> judgeIds = <String>{...ideathon.judgeIds};
    for (final EvaluationAssignmentModel a in assignments) {
      if (a.ideaId.trim().isEmpty) continue;
      if (!snapshotById.containsKey(a.ideaId.trim())) continue;
      assignmentsByIdea.putIfAbsent(a.ideaId.trim(), () => <EvaluationAssignmentModel>[]).add(a);
      if (a.judgeId.trim().isNotEmpty) judgeIds.add(a.judgeId.trim());
    }

    final Map<String, UserModel> judgeById = <String, UserModel>{
      for (final UserModel u in evaluators) u.userId: u,
    };
    final List<String> missingJudgeIds = judgeIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty && !judgeById.containsKey(id))
        .toList(growable: false);
    if (missingJudgeIds.isNotEmpty) {
      final List<UserModel?> fetched = await Future.wait<UserModel?>(
        missingJudgeIds.map(FirestoreUtils.fetchUser),
      );
      for (int i = 0; i < missingJudgeIds.length; i++) {
        final UserModel? user = fetched[i];
        if (user != null) judgeById[missingJudgeIds[i]] = user;
      }
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
    final Map<String, int> ideasByJudge = <String, int>{};
    for (final IdeathonJudgeAssignmentRow row in rows) {
      for (final String judgeId in row.assignedJudgeIds.toSet()) {
        ideasByJudge[judgeId] = (ideasByJudge[judgeId] ?? 0) + 1;
      }
    }
    final List<IdeathonJudgeWorkload> workloads = <IdeathonJudgeWorkload>[];
    final Set<String> rosterAndAssigned = <String>{...ideathon.judgeIds, ...ideasByJudge.keys};
    for (final String judgeId in rosterAndAssigned) {
      final String trimmed = judgeId.trim();
      if (trimmed.isEmpty) continue;
      workloads.add(
        IdeathonJudgeWorkload(
          judgeId: trimmed,
          displayName: judgeDisplayName(judgeById, trimmed),
          ideaCount: ideasByJudge[trimmed] ?? 0,
        ),
      );
    }
    workloads.sort((IdeathonJudgeWorkload a, IdeathonJudgeWorkload b) {
      final int byCount = b.ideaCount.compareTo(a.ideaCount);
      if (byCount != 0) return byCount;
      return a.displayName.compareTo(b.displayName);
    });

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
      workloads: workloads,
      evaluationLocked: evaluationLocked,
    );
  }

  static Future<bool> _evaluationLocked(IdeathonModel ideathon) async {
    if (IdeathonService.isEventCompleted(ideathon)) return true;
    return IdeathonService.hasEvaluationStarted(ideathon.ideathonId);
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
    if (await IdeathonService.hasEvaluationStarted(ideathonId)) {
      throw StateError('Judge assignments are locked because evaluation has started.');
    }
    final IdeathonModel? ideathon = await IdeathonService.fetchById(ideathonId);
    if (ideathon == null) throw StateError('Ideathon not found.');
    if (IdeathonService.isEventCompleted(ideathon)) {
      throw StateError('This event is completed. Judge assignments are locked.');
    }

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
    if (await IdeathonService.hasEvaluationStarted(ideathonId)) {
      throw StateError('Judge assignments are locked because evaluation has started.');
    }
    final IdeathonModel? event = await IdeathonService.fetchById(ideathonId);
    if (event != null && IdeathonService.isEventCompleted(event)) {
      throw StateError('This event is completed. Judge assignments are locked.');
    }
    await EvaluationAssignmentService.removeIdeathonAssignment(
      assignmentId: assignmentId,
      ideathonId: ideathonId,
    );
  }

  static Future<Map<String, TeamModel>> _loadTeams(Iterable<IdeaModel> ideas) async {
    final Set<String> teamIds = <String>{
      for (final IdeaModel idea in ideas)
        if (idea.teamId.trim().isNotEmpty) idea.teamId.trim(),
    };
    if (teamIds.isEmpty) return const <String, TeamModel>{};
    final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
      teamIds.map(
        (String teamId) => _db.collection(FirestoreUtils.hkzTeams).doc(teamId).get(),
      ),
    );
    final Map<String, TeamModel> byId = <String, TeamModel>{};
    for (final DocumentSnapshot<Map<String, dynamic>> doc in docs) {
      if (!doc.exists || doc.data() == null) continue;
      byId[doc.id] = TeamModel.fromMap(doc.id, doc.data()!);
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
