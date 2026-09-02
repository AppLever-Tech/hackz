import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../organization/models/department_model.dart';
import '../../problems/models/problem_model.dart';
import '../models/team_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../models/enums/team_status.dart';
import '../../../utils/firestore_utils.dart';

class TeamRuleException implements Exception {
  TeamRuleException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TeamService {
  TeamService._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<TeamModel>> getTeamsLedBy(String userId) =>
      FirestoreUtils.getTeamsLedBy(userId);

  static Future<bool> userLeadsAnyTeam(String userId) async {
    final List<TeamModel> teams = await getTeamsLedBy(userId);
    return teams.any((TeamModel t) => t.status != TeamStatus.inactive);
  }

  static void requireTeamLeaderInMembers({
    required String teamLeaderId,
    required Iterable<String> memberIds,
  }) {
    final String leaderId = teamLeaderId.trim();
    if (leaderId.isEmpty) {
      throw TeamRuleException('A team leader is required.');
    }
    if (!memberIds.map((String id) => id.trim()).contains(leaderId)) {
      throw TeamRuleException('Team leader must be a team member.');
    }
  }

  static bool canManageTeam(UserModel actor, TeamModel team) {
    final String id = actor.userId.trim();
    if (id.isEmpty) return false;
    final UserRole role = UserRole.fromCode(actor.role);
    if (role == UserRole.teamMember) return isActingTeamLeader(actor, team);
    return false;
  }

  static void assertCanManageTeam(UserModel actor, TeamModel team) {
    if (!canManageTeam(actor, team)) {
      throw TeamRuleException('You can only manage teams you lead.');
    }
  }

  /// Team Leader capability: `currentUserId == team.teamLeaderId` and membership.
  static bool isActingTeamLeader(UserModel actor, TeamModel team) {
    final String id = actor.userId.trim();
    return id.isNotEmpty && team.isLedBy(id) && team.isMember(id);
  }

  static void assertCanSubmitIdea(UserModel actor, TeamModel team) {
    if (!isActingTeamLeader(actor, team)) {
      throw TeamRuleException('Only the team leader can submit an idea for this team.');
    }
  }

  static void assertCanPayForTeam(UserModel actor, TeamModel team) {
    if (!isActingTeamLeader(actor, team)) {
      throw TeamRuleException('Only the team leader can submit payment for this team.');
    }
  }

  static Future<List<UserModel>> getDepartmentTeamMembers({
    required String orgId,
    required String departmentCode,
  }) =>
      FirestoreUtils.getDepartmentUsers(
        orgId: orgId,
        department: departmentCode,
        roleCodes: <String>[UserRole.teamMember.code],
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
    required UserModel actor,
    required String teamName,
    required Set<String> selectedMemberIds,
    required String teamLeaderId,
    required List<TeamModel> existingTeams,
    required List<UserModel> departmentTeamMembers,
    TeamModel? editingTeam,
  }) async {
    final String trimmedName = teamName.trim();
    if (trimmedName.isEmpty) {
      throw TeamRuleException('Team name is required.');
    }
    final String normalizedName = trimmedName.toLowerCase();
    for (final TeamModel team in existingTeams) {
      if (editingTeam != null && team.teamId == editingTeam.teamId) continue;
      if (team.teamName.trim().toLowerCase() == normalizedName) {
        throw TeamRuleException('A team with this name already exists. Choose a different name.');
      }
    }
    if (selectedMemberIds.length < 2 || selectedMemberIds.length > 4) {
      throw TeamRuleException('Team size must be between 2 and 4 team members.');
    }
    requireTeamLeaderInMembers(teamLeaderId: teamLeaderId, memberIds: selectedMemberIds);

    final UserRole role = UserRole.fromCode(actor.role);
    if (role == UserRole.teamMember) {
      if (!selectedMemberIds.contains(actor.userId.trim())) {
        throw TeamRuleException('The team leader must be a member of the team.');
      }
      if (teamLeaderId.trim() != actor.userId.trim()) {
        throw TeamRuleException('You can only designate yourself as team leader of your team.');
      }
      if (editingTeam == null && existingTeams.isNotEmpty) {
        throw TeamRuleException('A team member can belong to only one team.');
      }
      if (editingTeam != null) {
        assertCanManageTeam(actor, editingTeam);
      }
    } else if (role == UserRole.departmentAdmin) {
      if (editingTeam != null) {
        throw TeamRuleException('You can only manage teams you lead.');
      }
    } else {
      throw TeamRuleException('Only a team leader can create or update a team.');
    }

    final deptCode = actor.departmentCode.trim().toUpperCase();
    final membersById = <String, UserModel>{for (final s in departmentTeamMembers) s.userId: s};
    for (final memberId in selectedMemberIds) {
      final member = membersById[memberId];
      if (member == null) {
        throw TeamRuleException('Selected team member not found in department.');
      }
      if (member.departmentCode.trim().toUpperCase() != deptCode) {
        throw TeamRuleException('All team members must belong to the same department.');
      }
      final existingTeamId = (member.teamId ?? '').trim();
      if (existingTeamId.isNotEmpty && existingTeamId != editingTeam?.teamId) {
        throw TeamRuleException('A team member can belong to only one team.');
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
    required UserModel actor,
    required String teamName,
    required Set<String> studentIds,
    required String teamLeaderId,
  }) async {
    requireTeamLeaderInMembers(teamLeaderId: teamLeaderId, memberIds: studentIds);
    final doc = _db.collection(FirestoreUtils.hkzTeams).doc();
    final team = TeamModel(
      teamId: doc.id,
      teamName: teamName.trim(),
      teamLeaderId: teamLeaderId.trim(),
      studentIds: studentIds.toList(growable: false),
      orgId: actor.orgId,
      departmentCode: actor.departmentCode.trim().toUpperCase(),
      status: TeamStatus.active,
      createdAt: DateTime.now(),
      createdBy: actor.userId.trim(),
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

  /// Department Admin: set [teamLeaderId] on an existing team. Leader stays a team member.
  static Future<void> assignTeamLeader({
    required UserModel actor,
    required TeamModel team,
    required String teamLeaderId,
  }) async {
    if (UserRole.fromCode(actor.role) != UserRole.departmentAdmin) {
      throw TeamRuleException('Only a department admin can assign a team leader.');
    }
    if (team.status == TeamStatus.inactive) {
      throw TeamRuleException('Cannot assign a leader on an inactive team.');
    }
    final String dept = actor.departmentCode.trim().toUpperCase();
    if (team.orgId.trim() != actor.orgId.trim() || team.departmentCode.trim().toUpperCase() != dept) {
      throw TeamRuleException('You can only assign leaders for teams in your department.');
    }
    requireTeamLeaderInMembers(teamLeaderId: teamLeaderId, memberIds: team.studentIds);
    await _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId).set(
      <String, dynamic>{'teamLeaderId': teamLeaderId.trim()},
      SetOptions(merge: true),
    );
  }

  static Future<List<TeamModel>> getTeamsByOrg(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return const <TeamModel>[];
    final snapshot = await _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: id).get();
    final teams = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => TeamModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    teams.sort((TeamModel a, TeamModel b) => b.createdAt.compareTo(a.createdAt));
    return teams;
  }

  static Future<void> updateTeam({
    required TeamModel team,
    required String teamName,
    required Set<String> studentIds,
    required String teamLeaderId,
  }) async {
    requireTeamLeaderInMembers(teamLeaderId: teamLeaderId, memberIds: studentIds);
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
        'teamLeaderId': teamLeaderId.trim(),
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
      if (status != IdeaStatus.draft) return false;
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
    if (snapshot.docs.isNotEmpty) {
      throw TeamRuleException('Only one active idea allowed per team and problem.');
    }
  }

  static Future<IdeaModel> submitIdea({
    required UserModel actor,
    required TeamModel team,
    required ProblemModel problem,
    required String ideaTitle,
    required String description,
    required List<PlatformFile> attachmentFiles,
    String gitRepositoryUrl = '',
    String youtubeDemoUrl = '',
  }) async {
    assertCanSubmitIdea(actor, team);
    await validateIdeaCreation(teamId: team.teamId, problemId: problem.problemId);
    final teamDept = DepartmentModel.resolveCode(team.departmentCode);
    final problemDept = DepartmentModel.resolveCode(problem.departmentCode);
    final doc = _db.collection(FirestoreUtils.hkzIdeas).doc();
    final idea = IdeaModel(
      ideaId: doc.id,
      problemId: problem.problemId,
      teamId: team.teamId,
      ideaTitle: ideaTitle.trim(),
      description: description.trim(),
      files: const <String>[],
      status: IdeaStatus.submitted,
      createdAt: DateTime.now(),
      orgId: actor.orgId,
      teamDepartmentCode: teamDept,
      problemDepartmentCode: problemDept,
      problemNumber: problem.problemNumber,
      problemTitle: problem.title,
      createdBy: actor.userId,
      gitRepositoryUrl: gitRepositoryUrl.trim(),
      youtubeDemoUrl: youtubeDemoUrl.trim(),
    );
    final batch = _db.batch();
    batch.set(doc, idea.toMap());
    batch.set(
      _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId),
      <String, dynamic>{'status': TeamStatus.locked.value},
      SetOptions(merge: true),
    );
    await batch.commit();

    if (attachmentFiles.isNotEmpty) {
      final uploaded = await AttachmentService.uploadAttachments(
        entityType: AttachmentEntityType.idea,
        entityId: doc.id,
        orgId: actor.orgId,
        departmentCode: teamDept,
        uploadedBy: actor.userId,
        files: attachmentFiles,
        fileType: 'idea',
      );
      final urls = uploaded.map((e) => e.downloadUrl).toList(growable: false);
      await doc.update(<String, dynamic>{'files': urls});
    }
    return idea;
  }

  static Future<bool> canSwitchMemberTeam({
    required String? currentTeamId,
  }) async {
    final teamId = (currentTeamId ?? '').trim();
    if (teamId.isEmpty) return true;
    final ideas = await _db.collection(FirestoreUtils.hkzIdeas).where('teamId', isEqualTo: teamId).get();
    return ideas.docs.isEmpty;
  }
}
