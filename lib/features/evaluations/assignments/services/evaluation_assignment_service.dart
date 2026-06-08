import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/team/models/team_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/user_model.dart';
import '../../../../utils/firestore_utils.dart';
import '../../services/evaluation_aggregation_sync_service.dart';
import '../models/evaluation_assignment_conflict.dart';
import '../models/evaluation_assignment_group_model.dart';
import '../models/evaluation_assignment_model.dart';

class EvaluationAssignmentService {
  EvaluationAssignmentService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Set<String>> assignedIdeaIdsForJudge({
    required String orgId,
    required String judgeId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: orgId)
        .where('judgeId', isEqualTo: judgeId)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value)
        .get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final String id = ((doc.data()['ideaId'] as String?) ?? '').trim();
          return id;
        })
        .where((String ideaId) => ideaId.isNotEmpty)
        .toSet();
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
      if (filterIds != null && !filterIds.contains(assignment.ideaId)) continue;
      byIdea.putIfAbsent(assignment.ideaId, () => <String>[]).add(assignment.judgeId);
    }
    return byIdea;
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

  static bool isFacultyOnlyEvaluator(UserModel user) {
    final bool isFaculty =
        user.hasRoleCode(UserRole.faculty.code) || user.role.trim() == UserRole.faculty.code;
    final bool isJudge =
        user.hasRoleCode(UserRole.judge.code) || user.role.trim() == UserRole.judge.code;
    return isFaculty && !isJudge;
  }

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

    final bool facultyOnly = isFacultyOnlyEvaluator(judge);
    if (!facultyOnly) {
      if (idea.createdBy.trim() == judgeId) {
        reasons.add('Self-submitted idea');
      }
      final TeamModel? t = team;
      if (t != null && t.studentIds.contains(judgeId)) {
        reasons.add('Judge is a member of this team');
      }
    }

    final TeamModel? t = team;
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
    for (final IdeaModel idea in ideaList) {
      await EvaluationAggregationSyncService.markUnderEvaluation(ideaId: idea.ideaId);
    }
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
