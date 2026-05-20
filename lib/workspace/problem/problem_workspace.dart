import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/attachment_model.dart';
import '../../models/idea_model.dart';
import '../../models/organization_model.dart';
import '../../models/payment_model.dart';
import '../../models/problem_model.dart';
import '../../models/score_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../user/user_workspace.dart';
import '../idea/idea_workspace.dart';
import 'problem_workspace_body.dart';

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
    required this.attachments,
    required this.ideasSubmitted,
    required this.approvedIdeas,
    required this.evaluatedIdeas,
    required this.totalIdeas,
    required this.verifiedPayments,
    required this.totalPayments,
    required this.topIdeas,
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
  final List<AttachmentModel> attachments;
  final int ideasSubmitted;
  final int approvedIdeas;
  final int evaluatedIdeas;
  final int totalIdeas;
  final int verifiedPayments;
  final int totalPayments;
  final List<ProblemIdeaPreview> topIdeas;
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

abstract final class ProblemWorkspace {
  static void push(BuildContext context, String problemId) {
    final String id = problemId.trim();
    if (id.isEmpty) return;
    final String routeId = 'problem:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;

    late ProblemWorkspaceViewModel vm;
    HkzWorkspace.push(
      context,
      WorkspaceRoute(
        id: routeId,
        title: 'Problem Details',
        subtitle: WorkspaceRoute.loadingSubtitle,
        prepare: () async {
          vm = await _load(id);
        },
        builder: (BuildContext context) => ProblemWorkspaceBody(vm: vm),
      ),
    );
  }

  static void open(BuildContext context, String problemId) {
    final String id = problemId.trim();
    if (id.isEmpty) return;
    final String routeId = 'problem:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;

    late ProblemWorkspaceViewModel vm;
    HkzWorkspace.open(
      context,
      WorkspaceRoute(
        id: routeId,
        title: 'Problem Details',
        subtitle: WorkspaceRoute.loadingSubtitle,
        prepare: () async {
          vm = await _load(id);
        },
        builder: (BuildContext context) => ProblemWorkspaceBody(vm: vm),
      ),
    );
  }

  static void openUserFromProblem(BuildContext context, String userId) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == 'user:$id') return;
    UserWorkspace.push(context, id);
  }

  static void openIdeaFromProblem(BuildContext context, ProblemIdeaPreview preview) {
    IdeaWorkspace.push(context, preview.idea.ideaId);
  }

  static Future<ProblemWorkspaceViewModel> _load(String problemId) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final doc = await db.collection(FirestoreUtils.hkzProblems).doc(problemId).get();
    if (!doc.exists || doc.data() == null) {
      throw StateError('Problem not found');
    }
    final Map<String, dynamic> raw = doc.data()!;
    final model = (await FirestoreUtils.fetchProblemById(problemId))!;
    final String orgId = model.orgId.trim();

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.fetchOrganization(orgId),
      FirestoreUtils.fetchUser(model.createdBy),
      db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: orgId).where('problemId', isEqualTo: model.problemId).limit(500).get(),
      db.collection(FirestoreUtils.hkzAttachments).where('orgId', isEqualTo: orgId).where('isActive', isEqualTo: true).limit(800).get(),
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
        .map((d) => IdeaModel.fromMap(d.id, d.data()))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> ideaIds = ideas.map((e) => e.ideaId).toSet();
    final List<AttachmentModel> attachments = attachmentSnap.docs
        .map((d) => AttachmentModel.fromMap(d.id, d.data()))
        .where((a) => a.entityType == AttachmentEntityType.problem && a.entityId == model.problemId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final List<PaymentModel> payments = paymentsSnap.docs
        .map((d) => PaymentModel.fromMap(d.id, d.data()))
        .where((p) => ideaIds.contains(p.ideaId))
        .toList(growable: false);

    final List<ScoreModel> scores = scoresSnap.docs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => ideaIds.contains(s.ideaId))
        .toList(growable: false);
    final Map<String, List<ScoreModel>> scoresByIdea = <String, List<ScoreModel>>{};
    for (final ScoreModel s in scores) {
      scoresByIdea.putIfAbsent(s.ideaId, () => <ScoreModel>[]).add(s);
    }

    final Map<String, UserModel> usersById = <String, UserModel>{};
    for (final d in usersSnap.docs) {
      final u = UserModel.fromMap(d.data());
      final id = u.userId.trim().isEmpty ? d.id : u.userId.trim();
      usersById[id] = u;
    }

    final int approvedIdeas = ideas.where((i) => i.status == IdeaStatus.approved).length;
    final int evaluatedIdeas = ideas.where((i) => scoresByIdea[i.ideaId]?.isNotEmpty == true).length;
    final int verifiedPayments = payments.where((p) => p.status == PaymentRecordStatus.verified).length;

    final topIdeas = ideas.take(5).map((idea) {
      final creator = usersById[idea.createdBy];
      final sc = scoresByIdea[idea.ideaId] ?? const <ScoreModel>[];
      final avg = sc.isEmpty ? null : sc.map((e) => e.score).reduce((a, b) => a + b) / sc.length;
      return ProblemIdeaPreview(
        idea: idea,
        createdByName: creator == null ? idea.createdBy : userDisplayName(creator),
        createdByUserId: idea.createdBy,
        avgScore: avg,
      );
    }).toList(growable: false);

    final String dept = model.departmentCode.trim().toUpperCase();
    final int coordinators = usersById.values.where((u) => u.role == 'COO' && u.departmentCode.trim().toUpperCase() == dept).length;
    final int judges = usersById.values.where((u) => u.role == 'JUD' && u.departmentCode.trim().toUpperCase() == dept).length;

    final String createdByName = createdByUser == null ? model.createdBy : userDisplayName(createdByUser);
    final String orgName = (org?.name.trim() ?? '').isEmpty ? model.orgId : org!.name.trim();
    final List<String> tags = model.tags.where((e) => e.trim().isNotEmpty).toList(growable: false);

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
      attachments: attachments,
      ideasSubmitted: ideas.length,
      approvedIdeas: approvedIdeas,
      evaluatedIdeas: evaluatedIdeas,
      totalIdeas: ideas.length,
      verifiedPayments: verifiedPayments,
      totalPayments: payments.length,
      topIdeas: topIdeas,
      coordinatorCount: coordinators,
      judgeCount: judges,
    );
  }
}
