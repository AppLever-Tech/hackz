import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../features/team/models/enums/team_status.dart';
import '../../models/idea_model.dart';
import '../../models/organization_model.dart';
import '../../models/payment_model.dart';
import '../../features/problems/models/problem_model.dart';
import '../../models/score_model.dart';
import '../../features/team/models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../core/workspace_attachment_counts.dart';

class IdeaWorkspaceViewModel {
  const IdeaWorkspaceViewModel({
    required this.idea,
    required this.problem,
    required this.team,
    required this.organizationName,
    required this.problemTitle,
    required this.teamName,
    required this.mentorName,
    required this.mentorId,
    required this.submittedByName,
    required this.payment,
    required this.scores,
    required this.averageScore,
    required this.reviewerCount,
    required this.evaluationProgressLabel,
    required this.paymentStatusLabel,
    required this.attachmentCounts,
    required this.attachments,
    required this.judgeNamesById,
  });

  final IdeaModel idea;
  final ProblemModel problem;
  final TeamModel team;
  final String organizationName;
  final String problemTitle;
  final String teamName;
  final String mentorName;
  final String mentorId;
  final String submittedByName;
  final PaymentModel? payment;
  final List<ScoreModel> scores;
  final double? averageScore;
  final int reviewerCount;
  final String evaluationProgressLabel;
  final String paymentStatusLabel;
  final WorkspaceAttachmentCounts attachmentCounts;
  final List<AttachmentModel> attachments;
  final Map<String, String> judgeNamesById;

  int get attachmentCount => attachmentCounts.totalCount;
}

abstract final class IdeaWorkspaceLoader {
  static Future<IdeaWorkspaceViewModel> load(String ideaId) async {
    final String id = ideaId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ideaId must be non-empty');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Idea not found');
    }

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final String orgId = idea.orgId.trim();

    final Future<DocumentSnapshot<Map<String, dynamic>>?> teamFuture = idea.teamId.trim().isEmpty
        ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
        : db.collection(FirestoreUtils.hkzTeams).doc(idea.teamId.trim()).get();

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      teamFuture,
      idea.problemId.trim().isEmpty
          ? Future<ProblemModel?>.value(null)
          : FirestoreUtils.fetchProblemById(idea.problemId.trim()),
      orgId.isEmpty ? Future<OrganizationModel?>.value(null) : FirestoreUtils.fetchOrganization(orgId),
      _loadPayment(db, id),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzScores).limit(0).get(),
            )
          : db
              .collection(FirestoreUtils.hkzScores)
              .where('orgId', isEqualTo: orgId)
              .where('ideaId', isEqualTo: id)
              .limit(50)
              .get(),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzAttachments).limit(0).get(),
            )
          : db
              .collection(FirestoreUtils.hkzAttachments)
              .where('orgId', isEqualTo: orgId)
              .where('isActive', isEqualTo: true)
              .limit(300)
              .get(),
      FirestoreUtils.fetchUser(idea.createdBy.trim()),
    ]);

    final DocumentSnapshot<Map<String, dynamic>>? teamDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>?;
    final ProblemModel? fetchedProblem = results[1] as ProblemModel?;
    final OrganizationModel? org = results[2] as OrganizationModel?;
    final PaymentModel? payment = results[3] as PaymentModel?;
    final QuerySnapshot<Map<String, dynamic>> scoresSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> attachmentSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final UserModel? submittedBy = results[6] as UserModel?;

    final TeamModel team = teamDoc != null && teamDoc.exists && teamDoc.data() != null
        ? TeamModel.fromMap(teamDoc.id, teamDoc.data()!)
        : TeamModel(
            teamId: idea.teamId,
            teamName: '',
            mentorId: '',
            studentIds: const <String>[],
            orgId: idea.orgId,
            departmentCode: idea.teamDepartmentCode,
            status: TeamStatus.inactive,
            createdAt: idea.createdAt,
          );

    final ProblemModel problem = fetchedProblem ??
        ProblemModel(
          problemId: idea.problemId,
          problemNumber: idea.problemNumber,
          title: idea.problemTitle,
          description: '',
          orgId: idea.orgId,
          orgType: '',
          departmentCode: idea.problemDepartmentCode,
          createdBy: idea.createdBy,
          category: '',
          theme: '',
          tags: const <String>[],
          attachments: const <String>[],
          isActive: true,
          createdAt: idea.createdAt,
        );

    final UserModel? mentor = team.mentorId.trim().isEmpty
        ? null
        : await FirestoreUtils.fetchUser(team.mentorId.trim());

    final List<ScoreModel> scores = scoresSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => ScoreModel.fromMap(d.id, d.data()))
        .toList(growable: false)
      ..sort((ScoreModel a, ScoreModel b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> judgeIds = scores.map((ScoreModel s) => s.judgeId.trim()).where((e) => e.isNotEmpty).toSet();
    final Map<String, String> judgeNamesById = <String, String>{};
    await Future.wait<void>(
      judgeIds.map((String judgeId) async {
        final UserModel? judge = await FirestoreUtils.fetchUser(judgeId);
        if (judge != null) {
          judgeNamesById[judgeId] = userDisplayName(judge);
        }
      }),
    );

    final String? paymentId = payment?.paymentId.trim();
    final List<AttachmentModel> attachments = attachmentSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => AttachmentModel.fromMap(d.id, d.data()))
        .where(
          (AttachmentModel a) =>
              (a.entityType == AttachmentEntityType.idea && a.entityId == id) ||
              (paymentId != null &&
                  paymentId.isNotEmpty &&
                  a.entityType == AttachmentEntityType.payment &&
                  a.entityId == paymentId),
        )
        .toList(growable: false)
      ..sort((AttachmentModel a, AttachmentModel b) => b.createdAt.compareTo(a.createdAt));

    final WorkspaceAttachmentCounts attachmentCounts = WorkspaceAttachmentCounts.fromModels(attachments);

    final double? averageScore = scores.isEmpty
        ? null
        : scores.map((ScoreModel e) => e.score).reduce((double a, double b) => a + b) / scores.length;

    final String orgName = (org?.name.trim() ?? '').isEmpty ? (orgId.isEmpty ? '—' : orgId) : org!.name.trim();
    final String teamName = team.teamName.trim().isEmpty
        ? (team.teamId.trim().isEmpty ? '—' : team.teamId.trim())
        : team.teamName.trim();
    final String problemTitle = problem.title.trim().isEmpty
        ? (problem.problemNumber.trim().isEmpty ? 'Problem' : problem.problemNumber.trim())
        : problem.title.trim();
    final String mentorName = mentor == null
        ? (team.mentorId.trim().isEmpty ? '—' : team.mentorId.trim())
        : userDisplayName(mentor);
    final String submittedByName = submittedBy == null
        ? (idea.createdBy.trim().isEmpty ? '—' : idea.createdBy.trim())
        : userDisplayName(submittedBy);

    return IdeaWorkspaceViewModel(
      idea: idea,
      problem: problem,
      team: team,
      organizationName: orgName,
      problemTitle: problemTitle,
      teamName: teamName,
      mentorName: mentorName,
      mentorId: team.mentorId.trim(),
      submittedByName: submittedByName,
      payment: payment,
      scores: scores,
      averageScore: averageScore,
      reviewerCount: judgeIds.length,
      evaluationProgressLabel: _evaluationProgress(idea.status, scores.length),
      paymentStatusLabel: _paymentStatusLabel(payment?.status),
      attachmentCounts: attachmentCounts,
      attachments: attachments,
      judgeNamesById: judgeNamesById,
    );
  }

  static Future<PaymentModel?> _loadPayment(FirebaseFirestore db, String ideaId) async {
    final DocumentSnapshot<Map<String, dynamic>> primary =
        await db.collection(FirestoreUtils.hkzPayments).doc(ideaId).get();
    if (primary.exists && primary.data() != null) {
      return PaymentModel.fromMap(primary.id, primary.data()!);
    }
    final QuerySnapshot<Map<String, dynamic>> legacy = await db
        .collection(FirestoreUtils.hkzPayments)
        .where('ideaId', isEqualTo: ideaId)
        .limit(1)
        .get();
    if (legacy.docs.isEmpty) return null;
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = legacy.docs.first;
    return PaymentModel.fromMap(doc.id, doc.data());
  }

  static String _evaluationProgress(IdeaStatus status, int scoreCount) {
    if (scoreCount > 0) {
      return '$scoreCount review${scoreCount == 1 ? '' : 's'} recorded';
    }
    return switch (status) {
      IdeaStatus.evaluated || IdeaStatus.approved => 'Evaluated',
      IdeaStatus.underReview => 'Awaiting reviews',
      IdeaStatus.rejected => 'Closed',
      IdeaStatus.submitted => 'Submitted · pending review',
      IdeaStatus.pendingSubmission => 'Not yet submitted',
    };
  }

  static String _paymentStatusLabel(PaymentRecordStatus? status) {
    if (status == null) return 'Not uploaded';
    return switch (status) {
      PaymentRecordStatus.pending => 'Pending verification',
      PaymentRecordStatus.verified => 'Verified',
      PaymentRecordStatus.rejected => 'Rejected',
    };
  }
}

String ideaWorkspaceStatusLabel(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.pendingSubmission => 'Pending submission',
    IdeaStatus.submitted => 'Submitted',
    IdeaStatus.underReview => 'Under review',
    IdeaStatus.evaluated => 'Evaluated',
    IdeaStatus.approved => 'Approved',
    IdeaStatus.rejected => 'Rejected',
  };
}

IconData ideaWorkspaceStatusIcon(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.pendingSubmission => AppIcons.statusPendingSubmission,
    IdeaStatus.submitted => AppIcons.statusSubmitted,
    IdeaStatus.underReview => AppIcons.statusUnderReview,
    IdeaStatus.evaluated => AppIcons.statusEvaluated,
    IdeaStatus.approved => AppIcons.statusApproved,
    IdeaStatus.rejected => AppIcons.statusRejected,
  };
}
