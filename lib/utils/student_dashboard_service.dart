import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../core/theme/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import '../features/user/models/enums/user_role.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../features/organization/models/organization_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../features/problems/models/problem_model.dart';
import '../features/evaluations/models/score_model.dart';
import '../features/team/models/team_model.dart';
import '../features/user/models/user_model.dart';
import '../features/team/models/enums/team_status.dart';
import '../features/user/models/enums/user_status.dart';
import 'firestore_utils.dart';

class StudentDashboardService {
  StudentDashboardService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<StudentDashboardVm> load(UserModel student) async {
    final teamId = (student.teamId ?? '').trim();
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: student.orgId).get(),
      _db.collection(FirestoreUtils.hkzAttachments).where('orgId', isEqualTo: student.orgId).where('isActive', isEqualTo: true).get(),
      _db.collection(FirestoreUtils.hkzOrganizations).doc(student.orgId).get(),
    ]);

    final teamDocs = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final ideaDocs = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final paymentDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final scoreDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final userDocs = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final problemDocs = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs;
    final attachmentDocs = (results[6] as QuerySnapshot<Map<String, dynamic>>).docs;
    final orgDoc = results[7] as DocumentSnapshot<Map<String, dynamic>>;
    final organizationName = (orgDoc.exists && orgDoc.data() != null)
        ? OrganizationModel.fromMap(orgDoc.id, orgDoc.data()!).name.trim()
        : '';

    final usersById = <String, UserModel>{
      for (final d in userDocs)
        (UserModel.fromMap(d.data()).userId.trim().isEmpty ? d.id : UserModel.fromMap(d.data()).userId.trim()):
            UserModel.fromMap(d.data()),
    };

    TeamModel? team;
    if (teamId.isNotEmpty) {
      for (final d in teamDocs) {
        final t = TeamModel.fromMap(d.id, d.data());
        if (t.teamId == teamId) {
          team = t;
          break;
        }
      }
    }
    team ??= teamDocs
        .map((d) => TeamModel.fromMap(d.id, d.data()))
        .firstWhere(
          (t) => t.studentIds.contains(student.userId),
          orElse: () => TeamModel(
            teamId: '',
            teamName: '',
            mentorId: '',
            studentIds: const <String>[],
            orgId: student.orgId,
            departmentCode: student.departmentCode,
            status: teamDocs.isEmpty ? TeamStatus.inactive : TeamStatus.active,
            createdAt: DateTime.now(),
          ),
        );

    final resolvedTeam = team ??
        TeamModel(
          teamId: '',
          teamName: '',
          mentorId: '',
          studentIds: const <String>[],
          orgId: student.orgId,
          departmentCode: student.departmentCode,
          status: TeamStatus.inactive,
          createdAt: DateTime.now(),
        );

    final problemsById = <String, ProblemModel>{
      for (final d in problemDocs) d.id: ProblemModel.fromMap(d.id, d.data()),
    };
    final scopedIdeas = ideaDocs
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .where((idea) => idea.teamId == resolvedTeam.teamId || idea.createdBy == student.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final ideaIds = scopedIdeas.map((e) => e.ideaId).toSet();
    final scopedPayments = paymentDocs
        .map((d) => PaymentModel.fromMap(d.id, d.data()))
        .where((p) => ideaIds.contains(p.ideaId) || p.paidByStudentId == student.userId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final scoresByIdea = <String, List<ScoreModel>>{};
    for (final d in scoreDocs) {
      final s = ScoreModel.fromMap(d.id, d.data());
      if (!ideaIds.contains(s.ideaId)) continue;
      scoresByIdea.putIfAbsent(s.ideaId, () => <ScoreModel>[]).add(s);
    }
    for (final entry in scoresByIdea.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final attachmentCountByEntity = <String, int>{};
    for (final d in attachmentDocs) {
      final attachment = AttachmentModel.fromMap(d.id, d.data());
      final entityType = attachment.entityType;
      if (entityType != AttachmentEntityType.idea && entityType != AttachmentEntityType.payment) continue;
      if (entityType == AttachmentEntityType.idea && !ideaIds.contains(attachment.entityId)) continue;
      if (entityType == AttachmentEntityType.payment &&
          !scopedPayments.any((payment) => payment.paymentId == attachment.entityId)) {
        continue;
      }
      final key = '${entityType.value}:${attachment.entityId}';
      attachmentCountByEntity[key] = (attachmentCountByEntity[key] ?? 0) + 1;
    }

    final pendingIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.draft).length;
    final submittedIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.submitted).length;
    final reviewIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.underEvaluation).length;
    final evaluatedIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.evaluated).length;
    final approvedIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.shortlisted).length;
    final rejectedIdeas = scopedIdeas.where((i) => i.status == IdeaStatus.rejected).length;
    final approvedOrRejectedIdeas = approvedIdeas + rejectedIdeas;

    final allScores = scoresByIdea.values.expand((x) => x).toList(growable: false);
    final avgScore = allScores.isEmpty
        ? null
        : allScores.map((e) => e.score).reduce((a, b) => a + b) / allScores.length;
    final highestScore = allScores.isEmpty
        ? null
        : allScores.map((e) => e.score).reduce((a, b) => a > b ? a : b);

    final pendingPayments = scopedPayments.where((p) => p.status == PaymentRecordStatus.pending).length;
    final verifiedPayments = scopedPayments.where((p) => p.status == PaymentRecordStatus.verified).length;
    final rejectedPayments = scopedPayments.where((p) => p.status == PaymentRecordStatus.rejected).length;

    final mentor = usersById[resolvedTeam.mentorId];
    final teamMembers = resolvedTeam.studentIds
        .map((id) => usersById[id])
        .whereType<UserModel>()
        .toList(growable: false);
    final departmentAdmin = usersById.values.firstWhere(
      (u) => UserRole.fromCode(u.role) == UserRole.departmentAdmin && u.departmentCode == student.departmentCode,
      orElse: () => _emptyUser('DADM'),
    );
    final collegeAdmin = usersById.values.firstWhere(
      (u) => UserRole.fromCode(u.role) == UserRole.collegeAdmin,
      orElse: () => _emptyUser('CADM'),
    );

    final ideaCards = scopedIdeas
        .map(
          (idea) => StudentIdeaItem(
            idea: idea,
            problemDepartment: problemsById[idea.problemId]?.departmentDisplayName ?? idea.problemDepartmentCode,
            payment: scopedPayments.where((p) => p.ideaId == idea.ideaId).cast<PaymentModel?>().firstWhere(
                  (p) => p != null,
                  orElse: () => null,
                ),
            latestScore: scoresByIdea[idea.ideaId]?.first,
            scoreCount: scoresByIdea[idea.ideaId]?.length ?? 0,
            feedbackSummary: scoresByIdea[idea.ideaId]
                    ?.where((s) => s.feedback.trim().isNotEmpty)
                    .map((s) => s.feedback.trim())
                    .join(' | ') ??
                '',
            attachmentCount: attachmentCountByEntity['idea:${idea.ideaId}'] ?? 0,
          ),
        )
        .toList(growable: false);

    final activities = <StudentActivityItem>[
      ...scopedIdeas.map(
        (i) => StudentActivityItem(
          text: 'Idea submitted: ${i.ideaTitle.trim().isEmpty ? i.problemNumber : i.ideaTitle.trim()}',
          at: i.createdAt,
          icon: AppIcons.ideas,
        ),
      ),
      ...scopedPayments.map(
        (p) => StudentActivityItem(
          text: 'Payment ${p.status.value} for ${p.problemNumber}',
          at: p.createdAt,
          icon: AppIcons.payments,
        ),
      ),
      ...allScores.map(
        (s) => StudentActivityItem(
          text: 'Evaluation completed (${s.score.toStringAsFixed(1)})',
          at: s.createdAt,
          icon: AppIcons.statusEvaluated,
        ),
      ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return StudentDashboardVm(
      studentId: student.userId,
      studentName: _fullName(student),
      department: student.department.isEmpty ? student.departmentCode : student.department,
      organizationName: organizationName.isEmpty ? student.orgId : organizationName,
      team: resolvedTeam,
      teamMembers: teamMembers,
      mentorId: mentor?.userId ?? '',
      mentorName: _fullName(mentor),
      departmentAdminId: departmentAdmin.userId,
      departmentAdminName: _fullName(departmentAdmin),
      collegeAdminId: collegeAdmin.userId,
      collegeAdminName: _fullName(collegeAdmin),
      teamMemberCount: resolvedTeam.studentIds.length,
      pendingIdeas: pendingIdeas,
      submittedIdeas: submittedIdeas,
      reviewIdeas: reviewIdeas,
      evaluatedIdeas: evaluatedIdeas,
      approvedIdeas: approvedIdeas,
      rejectedIdeas: rejectedIdeas,
      approvedOrRejectedIdeas: approvedOrRejectedIdeas,
      avgScore: avgScore,
      highestScore: highestScore,
      pendingPayments: pendingPayments,
      verifiedPayments: verifiedPayments,
      rejectedPayments: rejectedPayments,
      ideaCards: ideaCards,
      activities: activities.take(40).toList(growable: false),
      paymentAttachmentCounts: <String, int>{
        for (final p in scopedPayments) p.paymentId: attachmentCountByEntity['payment:${p.paymentId}'] ?? 0,
      },
    );
  }

  static String _fullName(UserModel? user) {
    if (user == null) return '-';
    final v = '${user.firstName} ${user.lastName}'.trim();
    return v.isEmpty ? user.userId : v;
  }

  UserModel _emptyUser(String role) {
    return UserModel(
      userId: '',
      phone: '',
      firstName: '',
      lastName: '',
      email: '',
      role: role,
      orgType: null,
      orgId: '',
      department: '',
      departmentCode: '',
      status: UserStatus.pendingApproval,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class StudentDashboardVm {
  const StudentDashboardVm({
    required this.studentId,
    required this.studentName,
    required this.department,
    required this.organizationName,
    required this.team,
    required this.teamMembers,
    required this.mentorId,
    required this.mentorName,
    required this.departmentAdminId,
    required this.departmentAdminName,
    required this.collegeAdminId,
    required this.collegeAdminName,
    required this.teamMemberCount,
    required this.pendingIdeas,
    required this.submittedIdeas,
    required this.reviewIdeas,
    required this.evaluatedIdeas,
    required this.approvedIdeas,
    required this.rejectedIdeas,
    required this.approvedOrRejectedIdeas,
    required this.avgScore,
    required this.highestScore,
    required this.pendingPayments,
    required this.verifiedPayments,
    required this.rejectedPayments,
    required this.ideaCards,
    required this.activities,
    required this.paymentAttachmentCounts,
  });

  final String studentId;
  final String studentName;
  final String department;
  final String organizationName;
  final TeamModel team;
  final List<UserModel> teamMembers;
  final String mentorId;
  final String mentorName;
  final String departmentAdminId;
  final String departmentAdminName;
  final String collegeAdminId;
  final String collegeAdminName;
  final int teamMemberCount;
  final int pendingIdeas;
  final int submittedIdeas;
  final int reviewIdeas;
  final int evaluatedIdeas;
  final int approvedIdeas;
  final int rejectedIdeas;
  final int approvedOrRejectedIdeas;
  final double? avgScore;
  final double? highestScore;
  final int pendingPayments;
  final int verifiedPayments;
  final int rejectedPayments;
  final List<StudentIdeaItem> ideaCards;
  final List<StudentActivityItem> activities;
  final Map<String, int> paymentAttachmentCounts;
}

class StudentIdeaItem {
  const StudentIdeaItem({
    required this.idea,
    required this.problemDepartment,
    required this.payment,
    required this.latestScore,
    required this.scoreCount,
    required this.feedbackSummary,
    required this.attachmentCount,
  });

  final IdeaModel idea;
  final String problemDepartment;
  final PaymentModel? payment;
  final ScoreModel? latestScore;
  final int scoreCount;
  final String feedbackSummary;
  final int attachmentCount;
}

class StudentActivityItem {
  const StudentActivityItem({
    required this.text,
    required this.at,
    required this.icon,
  });

  final String text;
  final DateTime at;
  final IconData icon;
}
