import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../organization/models/organization_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../../models/score_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../../workspace/core/workspace_attachment_counts.dart';
import '../models/problem_model.dart';

class ProblemWorkspaceViewModel {
  const ProblemWorkspaceViewModel({
    required this.problem,
    required this.organizationName,
    required this.createdByName,
    required this.createdByUserId,
    required this.category,
    required this.theme,
    required this.difficulty,
    required this.priority,
    required this.tags,
    required this.attachmentCounts,
    required this.attachments,
    required this.ideasSubmitted,
    required this.approvedIdeas,
    required this.evaluatedIdeas,
    required this.totalIdeas,
    required this.verifiedPayments,
    required this.totalPayments,
    required this.topIdeas,
    required this.allIdeas,
    required this.coordinatorCount,
    required this.judgeCount,
  });

  final ProblemModel problem;
  final String organizationName;
  final String createdByName;
  final String createdByUserId;
  final String category;
  final String theme;
  final String difficulty;
  final String priority;
  final List<String> tags;
  final WorkspaceAttachmentCounts attachmentCounts;
  final List<AttachmentModel> attachments;
  final int ideasSubmitted;
  final int approvedIdeas;
  final int evaluatedIdeas;
  final int totalIdeas;
  final int verifiedPayments;
  final int totalPayments;
  final List<ProblemIdeaPreview> topIdeas;
  final List<ProblemIdeaPreview> allIdeas;
  final int coordinatorCount;
  final int judgeCount;
}

class ProblemIdeaPreview {
  const ProblemIdeaPreview({
    required this.idea,
    required this.createdByName,
    required this.createdByUserId,
    required this.avgScore,
  });

  final IdeaModel idea;
  final String createdByName;
  final String createdByUserId;
  final double? avgScore;
}

abstract final class ProblemWorkspaceLoader {
  static Future<ProblemWorkspaceViewModel> load(String problemId) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await db.collection(FirestoreUtils.hkzProblems).doc(problemId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Problem not found');
    }
    final Map<String, dynamic> raw = doc.data()!;
    final ProblemModel model = (await FirestoreUtils.fetchProblemById(problemId))!;
    final String orgId = model.orgId.trim();

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.fetchOrganization(orgId),
      FirestoreUtils.fetchUser(model.createdBy),
      db
          .collection(FirestoreUtils.hkzIdeas)
          .where('orgId', isEqualTo: orgId)
          .where('problemId', isEqualTo: model.problemId)
          .limit(500)
          .get(),
      db
          .collection(FirestoreUtils.hkzAttachments)
          .where('orgId', isEqualTo: orgId)
          .where('isActive', isEqualTo: true)
          .limit(800)
          .get(),
      db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).limit(800).get(),
      db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).limit(1200).get(),
      db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: orgId).limit(1200).get(),
    ]);

    final OrganizationModel? org = results[0] as OrganizationModel?;
    final UserModel? createdByUser = results[1] as UserModel?;
    final QuerySnapshot<Map<String, dynamic>> ideasSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> attachmentSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> paymentsSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> scoresSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> usersSnap = results[6] as QuerySnapshot<Map<String, dynamic>>;

    final List<IdeaModel> ideas = ideasSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => IdeaModel.fromMap(d.id, d.data()))
        .toList(growable: false)
      ..sort((IdeaModel a, IdeaModel b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> ideaIds = ideas.map((IdeaModel e) => e.ideaId).toSet();
    final List<AttachmentModel> attachments = attachmentSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => AttachmentModel.fromMap(d.id, d.data()))
        .where(
          (AttachmentModel a) =>
              a.entityType == AttachmentEntityType.problem && a.entityId == model.problemId,
        )
        .toList(growable: false)
      ..sort((AttachmentModel a, AttachmentModel b) => b.createdAt.compareTo(a.createdAt));
    final WorkspaceAttachmentCounts attachmentCounts = WorkspaceAttachmentCounts.fromModels(attachments);

    final List<PaymentModel> payments = paymentsSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => PaymentModel.fromMap(d.id, d.data()))
        .where((PaymentModel p) => ideaIds.contains(p.ideaId))
        .toList(growable: false);

    final List<ScoreModel> scores = scoresSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => ScoreModel.fromMap(d.id, d.data()))
        .where((ScoreModel s) => ideaIds.contains(s.ideaId))
        .toList(growable: false);
    final Map<String, List<ScoreModel>> scoresByIdea = <String, List<ScoreModel>>{};
    for (final ScoreModel s in scores) {
      scoresByIdea.putIfAbsent(s.ideaId, () => <ScoreModel>[]).add(s);
    }

    final Map<String, UserModel> usersById = <String, UserModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d in usersSnap.docs) {
      final UserModel u = UserModel.fromMap(d.data());
      final String id = u.userId.trim().isEmpty ? d.id : u.userId.trim();
      usersById[id] = u;
    }

    final int approvedIdeas = ideas.where((IdeaModel i) => i.status == IdeaStatus.shortlisted).length;
    final int evaluatedIdeas = ideas.where((IdeaModel i) => scoresByIdea[i.ideaId]?.isNotEmpty == true).length;
    final int verifiedPayments = payments.where((PaymentModel p) => p.status == PaymentRecordStatus.verified).length;

    final List<ProblemIdeaPreview> allIdeas = ideas.map((IdeaModel idea) {
      final UserModel? creator = usersById[idea.createdBy];
      final List<ScoreModel> sc = scoresByIdea[idea.ideaId] ?? const <ScoreModel>[];
      final double? avg = sc.isEmpty ? null : sc.map((ScoreModel e) => e.score).reduce((double a, double b) => a + b) / sc.length;
      return ProblemIdeaPreview(
        idea: idea,
        createdByName: creator == null ? idea.createdBy : userDisplayName(creator),
        createdByUserId: idea.createdBy,
        avgScore: avg,
      );
    }).toList(growable: false);

    final List<ProblemIdeaPreview> topIdeas = allIdeas.take(5).toList(growable: false);

    final String dept = model.departmentCode.trim().toUpperCase();
    final int coordinators =
        usersById.values.where((UserModel u) => u.role == 'COO' && u.departmentCode.trim().toUpperCase() == dept).length;
    final int judges =
        usersById.values.where((UserModel u) => u.role == 'JUD' && u.departmentCode.trim().toUpperCase() == dept).length;

    final String createdByName = createdByUser == null ? model.createdBy : userDisplayName(createdByUser);
    final String orgName = (org?.name.trim() ?? '').isEmpty ? model.orgId : org!.name.trim();
    final List<String> tags = model.tags.where((String e) => e.trim().isNotEmpty).toList(growable: false);

    return ProblemWorkspaceViewModel(
      problem: model,
      organizationName: orgName,
      createdByName: createdByName,
      createdByUserId: model.createdBy,
      category: ((raw['category'] as String?) ?? model.category).trim(),
      theme: ((raw['theme'] as String?) ?? model.theme).trim(),
      difficulty: ((raw['difficulty'] as String?) ?? '').trim(),
      priority: ((raw['priority'] as String?) ?? '').trim(),
      tags: tags,
      attachmentCounts: attachmentCounts,
      attachments: attachments,
      ideasSubmitted: ideas.length,
      approvedIdeas: approvedIdeas,
      evaluatedIdeas: evaluatedIdeas,
      totalIdeas: ideas.length,
      verifiedPayments: verifiedPayments,
      totalPayments: payments.length,
      topIdeas: topIdeas,
      allIdeas: allIdeas,
      coordinatorCount: coordinators,
      judgeCount: judges,
    );
  }
}
