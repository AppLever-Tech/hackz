import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/team/models/team_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../user/models/user_model.dart';
import '../../../../utils/firestore_utils.dart';
import '../models/evaluation_assignment_conflict.dart';
import '../models/evaluation_assignment_group_model.dart';
import '../models/evaluation_assignment_model.dart';

class EvaluationAssignmentService {
  EvaluationAssignmentService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Set<String>> assignedIdeaIdsForJudge({
    required String orgId,
    required String judgeId,
    String ideathonId = '',
  }) async {
    final List<EvaluationAssignmentModel> assignments = await listAssignmentsForJudge(
      orgId: orgId,
      judgeId: judgeId,
      ideathonId: ideathonId,
    );
    return assignments
        .map((EvaluationAssignmentModel a) => a.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
  }

  /// Active assignments for a judge, optionally limited to one Ideathon.
  static Future<List<EvaluationAssignmentModel>> listAssignmentsForJudge({
    required String orgId,
    required String judgeId,
    String ideathonId = '',
  }) async {
    final String org = orgId.trim();
    final String judge = judgeId.trim();
    if (org.isEmpty || judge.isEmpty) return const <EvaluationAssignmentModel>[];

    final String eventId = ideathonId.trim();
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: org)
        .where('judgeId', isEqualTo: judge)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value);
    if (eventId.isNotEmpty) {
      query = query.where('ideathonId', isEqualTo: eventId);
    }
    final QuerySnapshot<Map<String, dynamic>> snap = await query.get();
    final List<EvaluationAssignmentModel> list = snap.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              EvaluationAssignmentModel.fromMap(doc.id, doc.data()),
        )
        .toList(growable: false);
    if (eventId.isEmpty) {
      // Unscoped Scoring: include Ideathon assignments (primary path) and any
      // non-Ideathon rows that still exist.
      return list;
    }
    return list.where((EvaluationAssignmentModel a) => a.ideathonId.trim() == eventId).toList(growable: false);
  }

  static Future<Map<String, List<String>>> assignedJudgesByIdea({
    required String orgId,
    Iterable<String>? ideaIds,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: orgId)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value)
        .get();
    final Set<String>? filterIds = ideaIds == null ? null : ideaIds.toSet();
    final Map<String, List<String>> byIdea = <String, List<String>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final EvaluationAssignmentModel assignment =
          EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      if (assignment.ideaId.isEmpty || assignment.judgeId.isEmpty) continue;
      // Exclude Ideathon-scoped rows from problem/idea assignment views.
      if (assignment.isIdeathonAssignment) continue;
      if (filterIds != null && !filterIds.contains(assignment.ideaId)) continue;
      byIdea.putIfAbsent(assignment.ideaId, () => <String>[]).add(assignment.judgeId);
    }
    return byIdea;
  }

  /// Active assignments for a specific Ideathon event only.
  static Future<List<EvaluationAssignmentModel>> listByIdeathon({
    required String ideathonId,
  }) async {
    final String eventId = ideathonId.trim();
    if (eventId.isEmpty) return const <EvaluationAssignmentModel>[];
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('ideathonId', isEqualTo: eventId)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value)
        .get();
    return snap.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              EvaluationAssignmentModel.fromMap(doc.id, doc.data()),
        )
        .toList(growable: false);
  }

  /// Judge ids per idea for one Ideathon (ignores other events).
  static Future<Map<String, List<String>>> assignedJudgesByIdeaForIdeathon({
    required String ideathonId,
    Iterable<String>? ideaIds,
  }) async {
    final List<EvaluationAssignmentModel> assignments =
        await listByIdeathon(ideathonId: ideathonId);
    final Set<String>? filterIds = ideaIds == null ? null : ideaIds.toSet();
    final Map<String, List<String>> byIdea = <String, List<String>>{};
    for (final EvaluationAssignmentModel assignment in assignments) {
      if (assignment.ideaId.isEmpty || assignment.judgeId.isEmpty) continue;
      if (filterIds != null && !filterIds.contains(assignment.ideaId)) continue;
      byIdea.putIfAbsent(assignment.ideaId, () => <String>[]).add(assignment.judgeId);
    }
    return byIdea;
  }

  /// Assigns judges to ideas for a specific Ideathon.
  ///
  /// Uniqueness is [ideathonId] + [ideaId] + [judgeId]. Skips conflicts and
  /// already-active duplicates. Does not mutate IdeaStatus.
  static Future<void> assignIdeasToJudgesForIdeathon({
    required String orgId,
    required String actorUserId,
    required String ideathonId,
    required Iterable<IdeaModel> ideas,
    required Iterable<UserModel> judges,
    required Map<String, TeamModel> teamsById,
  }) async {
    final String eventId = ideathonId.trim();
    final String org = orgId.trim();
    if (eventId.isEmpty || org.isEmpty) {
      throw StateError('Ideathon and organization are required.');
    }
    final List<IdeaModel> ideaList = ideas.toList(growable: false);
    final List<UserModel> judgeList = judges.toList(growable: false);
    if (ideaList.isEmpty || judgeList.isEmpty) return;

    final CollectionReference<Map<String, dynamic>> col =
        _db.collection(FirestoreUtils.hkzEvaluationAssignments);
    final QuerySnapshot<Map<String, dynamic>> existing = await col
        .where('ideathonId', isEqualTo: eventId)
        .get();
    final Map<String, EvaluationAssignmentModel> byIdeaJudge =
        <String, EvaluationAssignmentModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in existing.docs) {
      final EvaluationAssignmentModel model =
          EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      byIdeaJudge['${model.ideaId}|${model.judgeId}'] = model;
    }

    final WriteBatch batch = _db.batch();
    final DateTime now = DateTime.now();
    bool wrote = false;
    for (final IdeaModel idea in ideaList) {
      final TeamModel? team = teamsById[idea.teamId.trim()];
      for (final UserModel judge in judgeList) {
        final EvaluationAssignmentConflict conflict = validateConflict(
          judge: judge,
          idea: idea,
          team: team,
        );
        if (conflict.isConflict) continue;
        final String key = '${idea.ideaId}|${judge.userId}';
        final EvaluationAssignmentModel? previous = byIdeaJudge[key];
        if (previous != null && previous.isActive) continue;
        final DocumentReference<Map<String, dynamic>> ref = previous == null
            ? col.doc()
            : col.doc(previous.assignmentId);
        final EvaluationAssignmentModel next = EvaluationAssignmentModel(
          assignmentId: ref.id,
          orgId: org,
          problemId: idea.problemId,
          ideaId: idea.ideaId,
          judgeId: judge.userId,
          status: EvaluationAssignmentStatus.active,
          assignedBy: actorUserId,
          assignedAt: previous?.assignedAt ?? now,
          updatedAt: now,
          ideathonId: eventId,
        );
        batch.set(ref, next.toMap(), SetOptions(merge: true));
        wrote = true;
      }
    }
    if (wrote) await batch.commit();
  }

  /// Soft-removes one Ideathon assignment (same idea may stay assigned in other events).
  static Future<void> removeIdeathonAssignment({
    required String assignmentId,
    required String ideathonId,
  }) async {
    final String id = assignmentId.trim();
    final String eventId = ideathonId.trim();
    if (id.isEmpty || eventId.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzEvaluationAssignments).doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Assignment not found.');
    }
    final EvaluationAssignmentModel model =
        EvaluationAssignmentModel.fromMap(doc.id, doc.data()!);
    if (model.ideathonId.trim() != eventId) {
      throw StateError('Assignment does not belong to this Ideathon.');
    }
    await removeAssignment(assignmentId: id);
  }

  static Future<Map<String, int>> workloadByJudge({
    required String orgId,
    Iterable<String>? judgeIds,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: orgId)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value)
        .get();
    final Set<String>? filter = judgeIds == null ? null : judgeIds.toSet();
    final Map<String, Set<String>> ideaSetByJudge = <String, Set<String>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final EvaluationAssignmentModel assignment =
          EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      if (assignment.judgeId.isEmpty || assignment.ideaId.isEmpty) continue;
      if (filter != null && !filter.contains(assignment.judgeId)) continue;
      ideaSetByJudge
          .putIfAbsent(assignment.judgeId, () => <String>{})
          .add(assignment.ideaId);
    }
    return <String, int>{
      for (final MapEntry<String, Set<String>> e in ideaSetByJudge.entries)
        e.key: e.value.length,
    };
  }

  static const String mentorConflictReason = 'Mentor Conflict';

  static EvaluationAssignmentConflict validateConflict({
    required UserModel judge,
    required IdeaModel idea,
    TeamModel? team,
  }) {
    final List<String> reasons = <String>[];
    final String judgeId = judge.userId.trim();
    if (judgeId.isEmpty) {
      return const EvaluationAssignmentConflict(
        isConflict: true,
        reasons: <String>['Invalid evaluator id'],
      );
    }

    if (idea.createdBy.trim() == judgeId) {
      reasons.add('Self-submitted idea');
    }
    final TeamModel? t = team;
    if (t != null && t.studentIds.contains(judgeId)) {
      reasons.add('Judge is a member of this team');
    }

    if (t != null && t.mentorId.trim() == judgeId) {
      reasons.add(mentorConflictReason);
    }

    return EvaluationAssignmentConflict(
      isConflict: reasons.isNotEmpty,
      reasons: reasons,
    );
  }

  static Future<String?> assignIdeasToJudges({
    required String orgId,
    required String actorUserId,
    required String problemId,
    required Iterable<IdeaModel> ideas,
    required Iterable<UserModel> judges,
    required Map<String, TeamModel> teamsById,
  }) async {
    final List<IdeaModel> ideaList = ideas.toList(growable: false);
    final List<UserModel> judgeList = judges.toList(growable: false);
    if (ideaList.isEmpty || judgeList.isEmpty) return null;

    await _ensureGroup(
      orgId: orgId,
      problemId: problemId,
      actorUserId: actorUserId,
    );

    final CollectionReference<Map<String, dynamic>> col =
        _db.collection(FirestoreUtils.hkzEvaluationAssignments);
    final QuerySnapshot<Map<String, dynamic>> existing = await col
        .where('orgId', isEqualTo: orgId)
        .where('problemId', isEqualTo: problemId)
        .get();
    final Map<String, EvaluationAssignmentModel> byIdeaJudge =
        <String, EvaluationAssignmentModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in existing.docs) {
      final EvaluationAssignmentModel model =
          EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      byIdeaJudge['${model.ideaId}|${model.judgeId}'] = model;
    }

    final WriteBatch batch = _db.batch();
    final DateTime now = DateTime.now();
    for (final IdeaModel idea in ideaList) {
      final TeamModel? team = teamsById[idea.teamId];
      for (final UserModel judge in judgeList) {
        final EvaluationAssignmentConflict conflict = validateConflict(
          judge: judge,
          idea: idea,
          team: team,
        );
        if (conflict.isConflict) {
          continue;
        }
        final String key = '${idea.ideaId}|${judge.userId}';
        final EvaluationAssignmentModel? previous = byIdeaJudge[key];
        if (previous != null && previous.isActive) {
          continue;
        }
        final DocumentReference<Map<String, dynamic>> ref = previous == null
            ? col.doc()
            : col.doc(previous.assignmentId);
        final EvaluationAssignmentModel next = EvaluationAssignmentModel(
          assignmentId: ref.id,
          orgId: orgId,
          problemId: problemId,
          ideaId: idea.ideaId,
          judgeId: judge.userId,
          status: EvaluationAssignmentStatus.active,
          assignedBy: actorUserId,
          assignedAt: previous?.assignedAt ?? now,
          updatedAt: now,
        );
        batch.set(ref, next.toMap(), SetOptions(merge: true));
      }
    }
    await batch.commit();
    return null;
  }

  static Future<String?> removeAssignment({
    required String assignmentId,
  }) async {
    await _db.collection(FirestoreUtils.hkzEvaluationAssignments).doc(assignmentId).update(
      <String, dynamic>{
        'status': EvaluationAssignmentStatus.removed.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
    return null;
  }

  static Future<void> _ensureGroup({
    required String orgId,
    required String problemId,
    required String actorUserId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> existing = await _db
        .collection(FirestoreUtils.hkzEvaluationGroups)
        .where('orgId', isEqualTo: orgId)
        .where('problemId', isEqualTo: problemId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestoreUtils.hkzEvaluationGroups).doc();
    final DateTime now = DateTime.now();
    final EvaluationAssignmentGroupModel group = EvaluationAssignmentGroupModel(
      groupId: ref.id,
      orgId: orgId,
      problemId: problemId,
      createdBy: actorUserId,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(group.toMap());
  }
}
