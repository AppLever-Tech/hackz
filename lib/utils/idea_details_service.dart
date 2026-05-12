import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attachment_model.dart';
import '../models/enums/team_status.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../models/problem_model.dart';
import '../models/score_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';

class IdeaDetailsService {
  IdeaDetailsService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<IdeaDetailsVm> load({
    required String ideaId,
    required String orgId,
  }) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzIdeas).doc(ideaId).get(),
      _db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: orgId).get(),
      _db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: orgId).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: orgId).get(),
      _db.collection(FirestoreUtils.hkzPayments).where('orgId', isEqualTo: orgId).get(),
      _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).get(),
      _db.collection(FirestoreUtils.hkzAttachments).where('orgId', isEqualTo: orgId).where('isActive', isEqualTo: true).get(),
    ]);

    final ideaDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    if (!ideaDoc.exists || ideaDoc.data() == null) {
      throw StateError('Idea not found.');
    }
    final idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    final teams = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((d) => TeamModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    final team = teams.firstWhere(
      (t) => t.teamId == idea.teamId,
      orElse: () => TeamModel(
        teamId: '',
        teamName: '',
        mentorId: '',
        studentIds: const <String>[],
        orgId: idea.orgId,
        departmentCode: idea.departmentCode,
        status: TeamStatus.inactive,
        createdAt: DateTime.now(),
      ),
    );
    final userDocs = (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
    final usersById = <String, UserModel>{};
    for (final doc in userDocs) {
      final user = UserModel.fromMap(doc.data());
      final normalizedUser = user.userId.trim().isNotEmpty ? user : user.copyWith(userId: doc.id);
      final userId = normalizedUser.userId.trim();
      if (userId.isNotEmpty) {
        usersById[userId] = normalizedUser;
      }
      if (doc.id.trim().isNotEmpty) {
        usersById[doc.id.trim()] = normalizedUser;
      }
    }
    final mentor = usersById[team.mentorId];
    final students = team.studentIds.map((id) => usersById[id]).whereType<UserModel>().toList(growable: false);
    final submittedBy = usersById[idea.createdBy];

    final problems = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((d) => ProblemModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    final problem = problems.firstWhere(
      (p) => p.problemId == idea.problemId,
      orElse: () => ProblemModel(
        problemId: '',
        problemNumber: idea.problemNumber,
        title: idea.problemTitle,
        description: '',
        orgId: idea.orgId,
        orgType: '',
        departmentCode: idea.departmentCode,
        createdBy: idea.createdBy,
        category: '',
        theme: '',
        tags: const <String>[],
        attachments: const <String>[],
        isActive: true,
        createdAt: idea.createdAt,
      ),
    );

    final payments = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((d) => PaymentModel.fromMap(d.id, d.data()))
        .where((p) => p.ideaId == idea.ideaId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final payment = payments.isEmpty ? null : payments.first;

    final scores = (results[5] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((d) => ScoreModel.fromMap(d.id, d.data()))
        .where((s) => s.ideaId == idea.ideaId)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final avgScore = scores.isEmpty ? null : scores.map((e) => e.score).reduce((a, b) => a + b) / scores.length;

    final attachments = (results[6] as QuerySnapshot<Map<String, dynamic>>).docs
        .map((d) => AttachmentModel.fromMap(d.id, d.data()))
        .where((a) => (a.entityType == AttachmentEntityType.idea && a.entityId == idea.ideaId) ||
            (payment != null && a.entityType == AttachmentEntityType.payment && a.entityId == payment.paymentId))
        .toList(growable: false);
    final ideaAttachments =
        attachments.where((a) => a.entityType == AttachmentEntityType.idea).toList(growable: false);
    final paymentAttachments =
        attachments.where((a) => a.entityType == AttachmentEntityType.payment).toList(growable: false);

    final activities = <IdeaActivityItem>[
      IdeaActivityItem(text: 'Idea created', at: idea.createdAt),
      if (payment != null) IdeaActivityItem(text: 'Payment ${payment.status.value}', at: payment.createdAt),
      ...scores.map((s) => IdeaActivityItem(text: 'Scored ${s.score.toStringAsFixed(1)}', at: s.createdAt)),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return IdeaDetailsVm(
      idea: idea,
      problem: problem,
      team: team,
      mentor: mentor,
      submittedBy: submittedBy,
      students: students,
      usersById: usersById,
      payment: payment,
      scores: scores,
      averageScore: avgScore,
      ideaAttachments: ideaAttachments,
      paymentAttachments: paymentAttachments,
      activities: activities,
    );
  }
}

class IdeaDetailsVm {
  const IdeaDetailsVm({
    required this.idea,
    required this.problem,
    required this.team,
    required this.mentor,
    required this.submittedBy,
    required this.students,
    required this.usersById,
    required this.payment,
    required this.scores,
    required this.averageScore,
    required this.ideaAttachments,
    required this.paymentAttachments,
    required this.activities,
  });

  final IdeaModel idea;
  final ProblemModel problem;
  final TeamModel team;
  final UserModel? mentor;
  final UserModel? submittedBy;
  final List<UserModel> students;
  final Map<String, UserModel> usersById;
  final PaymentModel? payment;
  final List<ScoreModel> scores;
  final double? averageScore;
  final List<AttachmentModel> ideaAttachments;
  final List<AttachmentModel> paymentAttachments;
  final List<IdeaActivityItem> activities;
}

class IdeaActivityItem {
  const IdeaActivityItem({required this.text, required this.at});
  final String text;
  final DateTime at;
}
