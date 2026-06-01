import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../../../models/attachment_model.dart';
import '../../organization/models/department_model.dart';
import '../models/enums/team_status.dart';
import '../../../models/idea_model.dart';
import '../../../models/payment_model.dart';
import '../../problems/models/problem_model.dart';
import '../models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/attachment_service.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import 'team_service.dart';

class FacultyTeamInsight {
  const FacultyTeamInsight({
    required this.team,
    required this.ideas,
    required this.paymentStatuses,
    required this.evaluationCount,
  });

  final TeamModel team;
  final List<IdeaModel> ideas;
  final List<PaymentRecordStatus> paymentStatuses;
  final int evaluationCount;

  int get submittedIdeas => ideas.where((idea) => idea.status != IdeaStatus.pendingSubmission).length;
  bool get hasIdeas => ideas.isNotEmpty;
  bool get hasPendingPayment => paymentStatuses.any((status) => status == PaymentRecordStatus.pending);
  bool get hasEvaluation => evaluationCount > 0 || ideas.any((idea) => idea.status == IdeaStatus.evaluated || idea.status == IdeaStatus.approved);
  bool get isLocked => team.status == TeamStatus.locked || hasIdeas;
}

class FacultyTeamsWorkspaceData {
  const FacultyTeamsWorkspaceData({
    required this.teams,
    required this.students,
    required this.studentNamesById,
    required this.insightsByTeamId,
    required this.problems,
  });

  final List<TeamModel> teams;
  final List<UserModel> students;
  final Map<String, String> studentNamesById;
  final Map<String, FacultyTeamInsight> insightsByTeamId;
  final List<ProblemModel> problems;

  int get totalStudents => teams.expand((team) => team.studentIds).toSet().length;
  int get activeIdeas => insightsByTeamId.values.fold<int>(0, (sum, insight) => sum + insight.ideas.length);
}

class FacultyTeamsService {
  FacultyTeamsService._();

  static const int maxTeamsPerFaculty = 3;
  static const int minStudentsPerTeam = 2;
  static const int maxStudentsPerTeam = 4;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, FacultyTeamsWorkspaceData> _cache = <String, FacultyTeamsWorkspaceData>{};
  static final Map<String, DateTime> _cacheAt = <String, DateTime>{};
  static const Duration _cacheTtl = Duration(minutes: 3);

  static void clearCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  static void _invalidate(String facultyId) {
    _cache.remove(facultyId);
    _cacheAt.remove(facultyId);
  }

  static Future<FacultyTeamsWorkspaceData> load(UserModel faculty, {bool forceRefresh = false}) async {
    final cached = _cache[faculty.userId];
    final cachedAt = _cacheAt[faculty.userId];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      TeamService.getFacultyTeams(faculty.userId),
      TeamService.getDepartmentStudents(orgId: faculty.orgId, departmentCode: faculty.departmentCode),
      TeamService.getDepartmentProblems(orgId: faculty.orgId, departmentCode: faculty.departmentCode),
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: faculty.orgId).get(),
      _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: faculty.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: faculty.orgId).get(),
    ]);

    final teams = results[0] as List<TeamModel>;
    final students = sortUsersByDisplayName(results[1] as List<UserModel>);
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

    final insights = <String, FacultyTeamInsight>{};
    for (final team in teams) {
      final teamIdeas = ideasByTeam[team.teamId] ?? const <IdeaModel>[];
      insights[team.teamId] = FacultyTeamInsight(
        team: team,
        ideas: teamIdeas,
        paymentStatuses: teamIdeas
            .map((idea) => paymentsByIdea[idea.ideaId])
            .whereType<PaymentRecordStatus>()
            .toList(growable: false),
        evaluationCount: teamIdeas.fold<int>(0, (sum, idea) => sum + (scoresByIdea[idea.ideaId] ?? 0)),
      );
    }

    final data = FacultyTeamsWorkspaceData(
      teams: teams,
      students: students,
      studentNamesById: <String, String>{for (final student in students) student.userId: userDisplayName(student)},
      insightsByTeamId: insights,
      problems: problems,
    );
    _cache[faculty.userId] = data;
    _cacheAt[faculty.userId] = DateTime.now();
    return data;
  }

  static bool canCreateTeam(List<TeamModel> existingTeams) => existingTeams.length < maxTeamsPerFaculty;

  static String capacityMessage(int teamCount) {
    final remaining = (maxTeamsPerFaculty - teamCount).clamp(0, maxTeamsPerFaculty).toInt();
    if (remaining == 0) return 'Team capacity reached';
    return remaining == 1 ? '1 team slot remaining' : '$remaining team slots remaining';
  }

  static Future<void> saveTeam({
    required UserModel faculty,
    required String teamName,
    required Set<String> studentIds,
    required List<TeamModel> existingTeams,
    required List<UserModel> departmentStudents,
    TeamModel? editingTeam,
  }) async {
    await TeamService.validateTeamUpsert(
      faculty: faculty,
      teamName: teamName,
      selectedStudentIds: studentIds,
      existingTeams: existingTeams,
      departmentStudents: departmentStudents,
      editingTeam: editingTeam,
    );
    if (editingTeam == null) {
      await TeamService.createTeam(faculty: faculty, teamName: teamName, studentIds: studentIds);
    } else {
      await TeamService.updateTeam(team: editingTeam, teamName: teamName, studentIds: studentIds);
    }
    _invalidate(faculty.userId);
  }

  static Future<void> disableTeam(TeamModel team) async {
    final batch = _db.batch();
    batch.set(
      _db.collection(FirestoreUtils.hkzTeams).doc(team.teamId),
      <String, dynamic>{'status': TeamStatus.inactive.value},
      SetOptions(merge: true),
    );
    for (final studentId in team.studentIds) {
      batch.set(_db.collection(FirestoreUtils.hkzUsers).doc(studentId), <String, dynamic>{'teamId': null}, SetOptions(merge: true));
    }
    await batch.commit();
    clearCache();
  }

  static Future<void> submitIdea({
    required UserModel faculty,
    required TeamModel team,
    required ProblemModel problem,
    required String ideaTitle,
    required String description,
    required List<PlatformFile> attachmentFiles,
    String gitRepositoryUrl = '',
    String youtubeDemoUrl = '',
  }) async {
    await TeamService.validateIdeaCreation(teamId: team.teamId, problemId: problem.problemId);
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
      status: IdeaStatus.pendingSubmission,
      createdAt: DateTime.now(),
      orgId: faculty.orgId,
      teamDepartmentCode: teamDept,
      problemDepartmentCode: problemDept,
      problemNumber: problem.problemNumber,
      problemTitle: problem.title,
      createdBy: faculty.userId,
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
        orgId: faculty.orgId,
        departmentCode: teamDept,
        uploadedBy: faculty.userId,
        files: attachmentFiles,
        fileType: 'idea',
      );
      final urls = uploaded.map((e) => e.downloadUrl).toList(growable: false);
      await doc.update(<String, dynamic>{'files': urls});
    }
    _invalidate(faculty.userId);
  }
}
