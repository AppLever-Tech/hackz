import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/idea_model.dart';
import '../features/problems/models/problem_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/enums/team_status.dart';
import 'firestore_utils.dart';

class TeamRuleException implements Exception {
  TeamRuleException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TeamService {
  TeamService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<TeamModel>> getFacultyTeams(String facultyId) =>
      FirestoreUtils.getFacultyTeams(facultyId);

  static Future<List<UserModel>> getDepartmentStudents({
    required String orgId,
    required String departmentCode,
  }) =>
      FirestoreUtils.getDepartmentUsers(
        orgId: orgId,
        department: departmentCode,
        roleCodes: const <String>['STU'],
        limit: 500,
      );

  static Future<List<ProblemModel>> getDepartmentProblems({
    required String orgId,
    required String departmentCode,
  }) =>
      FirestoreUtils.getActiveProblemsByDepartment(orgId: orgId, departmentCode: departmentCode);

  /// Active problems across all departments (for idea submission, etc.).
  static Future<List<ProblemModel>> getActiveProblemsForCollege(String orgId) =>
      FirestoreUtils.getActiveProblemsByCollege(orgId);

  static Future<void> validateTeamUpsert({
    required UserModel faculty,
    required String teamName,
    required Set<String> selectedStudentIds,
    required List<TeamModel> existingTeams,
    required List<UserModel> departmentStudents,
    TeamModel? editingTeam,
  }) async {
    if (teamName.trim().isEmpty) {
      throw TeamRuleException('Team name is required.');
    }
    if (selectedStudentIds.length < 2 || selectedStudentIds.length > 4) {
      throw TeamRuleException('Team size must be between 2 and 4 students.');
    }
    if (editingTeam == null && existingTeams.length >= 3) {
      throw TeamRuleException('Maximum 3 teams per faculty reached.');
    }

    final deptCode = faculty.departmentCode.trim().toUpperCase();
    final studentsById = <String, UserModel>{for (final s in departmentStudents) s.userId: s};
    for (final studentId in selectedStudentIds) {
      final student = studentsById[studentId];
      if (student == null) {
        throw TeamRuleException('Selected student not found in department.');
      }
      if (student.departmentCode.trim().toUpperCase() != deptCode) {
        throw TeamRuleException('All students must belong to the same department.');
      }
      final existingTeamId = (student.teamId ?? '').trim();
      if (existingTeamId.isNotEmpty && existingTeamId != editingTeam?.teamId) {
        throw TeamRuleException('A student can belong to only one team.');
      }
    }

    if (editingTeam != null) {
      if (editingTeam.status == TeamStatus.locked) {
        throw TeamRuleException('This team is locked after idea submission.');
      }
      final canEdit = await canEditTeam(editingTeam.teamId);
      if (!canEdit) {
        throw TeamRuleException('Team can be edited only while idea status is pending submission.');
      }
    }
  }

  static Future<String> createTeam({
    required UserModel faculty,
    required String teamName,
    required Set<String> studentIds,
  }) async {
    final doc = _db.collection(FirestoreUtils.hkzTeams).doc();
    final team = TeamModel(
      teamId: doc.id,
      teamName: teamName.trim(),
      mentorId: faculty.userId,
      studentIds: studentIds.toList(growable: false),
      orgId: faculty.orgId,
      departmentCode: faculty.departmentCode.trim().toUpperCase(),
      status: TeamStatus.active,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    batch.set(doc, team.toMap(), SetOptions(merge: true));
    for (final studentId in studentIds) {
      final userRef = _db.collection(FirestoreUtils.hkzUsers).doc(studentId);
      batch.set(userRef, <String, dynamic>{'teamId': doc.id}, SetOptions(merge: true));
    }
    await batch.commit();
    return doc.id;
  }

  static Future<void> updateTeam({
    required TeamModel team,
    required String teamName,
    required Set<String> studentIds,
  }) async {
    final prev = team.studentIds.toSet();
    final next = studentIds.toSet();
    final removed = prev.difference(next);
    final added = next.difference(prev);

    final batch = _db.batch();
    final teamRef = _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId);
    batch.set(
      teamRef,
      <String, dynamic>{
        'teamName': teamName.trim(),
        'studentIds': next.toList(growable: false),
      },
      SetOptions(merge: true),
    );
    for (final userId in removed) {
      batch.set(_db.collection(FirestoreUtils.hkzUsers).doc(userId), <String, dynamic>{'teamId': null}, SetOptions(merge: true));
    }
    for (final userId in added) {
      batch.set(_db.collection(FirestoreUtils.hkzUsers).doc(userId), <String, dynamic>{'teamId': team.teamId}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<void> deleteTeam(TeamModel team) async {
    final ideas = await _db.collection(FirestoreUtils.hkzIdeas).where('teamId', isEqualTo: team.teamId).limit(1).get();
    final batch = _db.batch();
    if (ideas.docs.isEmpty) {
      batch.delete(_db.collection(FirestoreUtils.hkzTeams).doc(team.teamId));
    } else {
      batch.set(
        _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId),
        <String, dynamic>{'status': TeamStatus.inactive.value},
        SetOptions(merge: true),
      );
    }
    for (final userId in team.studentIds) {
      batch.set(_db.collection(FirestoreUtils.hkzUsers).doc(userId), <String, dynamic>{'teamId': null}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<bool> canEditTeam(String teamId) async {
    final ideas = await _db.collection(FirestoreUtils.hkzIdeas).where('teamId', isEqualTo: teamId).get();
    if (ideas.docs.isEmpty) return true;
    for (final doc in ideas.docs) {
      final status = IdeaStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      if (status != IdeaStatus.pendingSubmission) return false;
    }
    return true;
  }

  static Future<void> validateIdeaCreation({
    required String teamId,
    required String problemId,
  }) async {
    final snapshot = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('teamId', isEqualTo: teamId)
        .where('problemId', isEqualTo: problemId)
        .get();
    if (snapshot.docs.isEmpty) return;
    final latest = snapshot.docs
        .map((d) => IdeaStatus.fromRaw((d.data()['status'] as String?) ?? ''))
        .toList(growable: false);
    final hasActive = latest.any((s) => s != IdeaStatus.rejected);
    if (hasActive) {
      throw TeamRuleException('Only one active idea allowed per team and problem.');
    }
  }

  static Future<bool> canSwitchStudentTeam({
    required String? currentTeamId,
  }) async {
    final teamId = (currentTeamId ?? '').trim();
    if (teamId.isEmpty) return true;
    final ideas = await _db.collection(FirestoreUtils.hkzIdeas).where('teamId', isEqualTo: teamId).get();
    if (ideas.docs.isEmpty) return true;
    return ideas.docs
        .map((d) => IdeaStatus.fromRaw((d.data()['status'] as String?) ?? ''))
        .every((s) => s == IdeaStatus.rejected);
  }
}
