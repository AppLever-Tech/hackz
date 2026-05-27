import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attachment_model.dart';
import '../models/department_model.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../features/problems/models/problem_model.dart';
import '../features/team/models/team_model.dart';
import '../models/user_model.dart';
import 'common_helpers.dart';
import 'firestore_utils.dart';
import 'idea_department_helpers.dart';
import 'payment_finance_helpers.dart';

typedef _Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

class DepartmentPaymentContribution {
  const DepartmentPaymentContribution({
    required this.payment,
    required this.ideaTitle,
    required this.problemTitle,
    required this.teamName,
    required this.mentorName,
    required this.studentCount,
    required this.coordinatorName,
    required this.hasProof,
    required this.isOverdue,
    required this.isRecentlyVerified,
    required this.needsAttention,
  });

  final PaymentModel payment;
  final String ideaTitle;
  final String problemTitle;
  final String teamName;
  final String mentorName;
  final int studentCount;
  final String coordinatorName;
  final bool hasProof;
  final bool isOverdue;
  final bool isRecentlyVerified;
  final bool needsAttention;
}

class DepartmentPaymentsSummary {
  const DepartmentPaymentsSummary({
    required this.totalCollection,
    required this.verifiedCount,
    required this.verifiedAmount,
    required this.pendingCount,
    required this.pendingAmount,
    required this.rejectedCount,
    required this.rejectedAmount,
  });

  final double totalCollection;
  final int verifiedCount;
  final double verifiedAmount;
  final int pendingCount;
  final double pendingAmount;
  final int rejectedCount;
  final double rejectedAmount;
}

class DepartmentPaymentDetail {
  const DepartmentPaymentDetail({
    required this.contribution,
    required this.idea,
    required this.team,
    required this.problem,
    required this.students,
    required this.proofAttachments,
    required this.departmentContributionPercent,
    required this.paymentTrendLabel,
  });

  final DepartmentPaymentContribution contribution;
  final IdeaModel? idea;
  final TeamModel? team;
  final ProblemModel? problem;
  final List<UserModel> students;
  final List<AttachmentModel> proofAttachments;
  final double departmentContributionPercent;
  final String paymentTrendLabel;
}

class DepartmentPaymentsWorkspace {
  const DepartmentPaymentsWorkspace({
    required this.summary,
    required this.contributions,
    required this.detailsByPaymentId,
  });

  final DepartmentPaymentsSummary summary;
  final List<DepartmentPaymentContribution> contributions;
  final Map<String, DepartmentPaymentDetail> detailsByPaymentId;

  DepartmentPaymentDetail? detailFor(String paymentId) {
    final id = paymentId.trim();
    if (id.isEmpty) return null;
    final direct = detailsByPaymentId[id];
    if (direct != null) return direct;
    for (final entry in detailsByPaymentId.values) {
      final payment = entry.contribution.payment;
      if (payment.paymentId == id || payment.ideaId == id) return entry;
    }
    return null;
  }
}

enum DepartmentPaymentDateFilter {
  all('All dates'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days');

  const DepartmentPaymentDateFilter(this.label);
  final String label;
}

enum DepartmentPaymentVerificationFilter {
  all('All'),
  verifiedOnly('Verified'),
  unverifiedOnly('Unverified');

  const DepartmentPaymentVerificationFilter(this.label);
  final String label;
}

class DepartmentPaymentsService {
  DepartmentPaymentsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, DepartmentPaymentsWorkspace> _cache = <String, DepartmentPaymentsWorkspace>{};
  static final Map<String, DateTime> _cacheAt = <String, DateTime>{};
  static const Duration _cacheTtl = Duration(minutes: 3);

  static void clearCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  static String _cacheKey(UserModel user) => '${user.orgId}::${user.departmentCode.trim().toUpperCase()}';

  static Future<_Docs> _fetchOrg(String collection, String orgId) async {
    final snap = await _db.collection(collection).where('orgId', isEqualTo: orgId).get();
    return snap.docs;
  }

  static Future<DepartmentPaymentsWorkspace> load(UserModel user, {bool forceRefresh = false}) async {
    final key = _cacheKey(user);
    final cached = _cache[key];
    final cachedAt = _cacheAt[key];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final dept = DepartmentModel.resolveCode(user.departmentCode);
    bool inFinanceDept(Map<String, dynamic> data) =>
        dept.isEmpty || ((data['departmentCode'] as String?) ?? '').trim().toUpperCase() == dept;

    final results = await Future.wait<_Docs>(<Future<_Docs>>[
      _fetchOrg(FirestoreUtils.hkzPayments, user.orgId),
      _fetchOrg(FirestoreUtils.hkzIdeas, user.orgId),
      _fetchOrg(FirestoreUtils.hkzTeams, user.orgId),
      _fetchOrg(FirestoreUtils.hkzUsers, user.orgId),
      _fetchOrg(FirestoreUtils.hkzProblems, user.orgId),
      _fetchOrg(FirestoreUtils.hkzAttachments, user.orgId),
    ]);

    final payments = results[0]
        .where((doc) => inFinanceDept(doc.data()))
        .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final paymentTeamIds = payments.map((p) => p.teamId.trim()).where((id) => id.isNotEmpty).toSet();

    final ideas = results[1]
        .where((doc) => IdeaDepartmentHelpers.matchesProblemDept(doc.data(), dept))
        .map((doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final teams = results[2]
        .where((doc) => paymentTeamIds.contains(doc.id))
        .map((doc) => TeamModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final teamMentorIds = teams.map((t) => t.mentorId.trim()).where((id) => id.isNotEmpty);
    final teamStudentIds = teams.expand((t) => t.studentIds);
    final paymentVerifierIds = payments.map((p) => p.verifiedBy.trim()).where((id) => id.isNotEmpty);
    final relatedUserIds = <String>{...teamMentorIds, ...teamStudentIds, ...paymentVerifierIds};
    final users = results[3]
        .where((doc) {
          final data = doc.data();
          final userId = ((data['userId'] as String?) ?? '').trim().isNotEmpty
              ? (data['userId'] as String).trim()
              : doc.id;
          return relatedUserIds.contains(userId);
        })
        .map((doc) {
          final data = doc.data();
          final userId = ((data['userId'] as String?) ?? '').trim().isNotEmpty
              ? (data['userId'] as String).trim()
              : doc.id;
          return UserModel.fromMap(<String, dynamic>{...data, 'userId': userId});
        })
        .toList(growable: false);
    final paymentProblemIds = payments.map((p) => p.problemId.trim()).where((id) => id.isNotEmpty).toSet();
    final problems = results[4]
        .where((doc) => paymentProblemIds.contains(doc.id) || inFinanceDept(doc.data()))
        .map((doc) => ProblemModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final paymentIds = payments.map((p) => p.paymentId).toSet();
    final attachments = results[5]
        .where((doc) {
          final data = doc.data();
          if (!inFinanceDept(data)) return false;
          final entityId = ((data['entityId'] as String?) ?? '').trim();
          return paymentIds.contains(entityId);
        })
        .map((doc) => AttachmentModel.fromMap(doc.id, doc.data()))
        .where((a) => a.isActive && a.entityType == AttachmentEntityType.payment)
        .toList(growable: false);

    final ideaById = <String, IdeaModel>{for (final i in ideas) i.ideaId: i};
    final teamById = <String, TeamModel>{for (final t in teams) t.teamId: t};
    final userById = <String, UserModel>{for (final u in users) u.userId: u};
    final problemById = <String, ProblemModel>{for (final p in problems) p.problemId: p};
    final attachmentsByPayment = <String, List<AttachmentModel>>{};
    for (final attachment in attachments) {
      attachmentsByPayment.putIfAbsent(attachment.entityId, () => <AttachmentModel>[]).add(attachment);
    }

    final summary = _buildSummary(payments);
    final contributions = <DepartmentPaymentContribution>[];
    final detailsByPaymentId = <String, DepartmentPaymentDetail>{};

    for (final payment in payments) {
      final idea = ideaById[payment.ideaId];
      final team = teamById[payment.teamId];
      final problem = problemById[payment.problemId];
      final proof = attachmentsByPayment[payment.paymentId] ?? const <AttachmentModel>[];
      final hasProof = payment.paymentProofUrl.trim().isNotEmpty || proof.isNotEmpty;
      final mentor = team == null ? null : userById[team.mentorId];
      final coordinator = payment.verifiedBy.trim().isEmpty ? null : userById[payment.verifiedBy.trim()];

      final contribution = DepartmentPaymentContribution(
        payment: payment,
        ideaTitle: _ideaTitle(idea),
        problemTitle: _problemTitle(idea, problem, payment),
        teamName: team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : payment.teamId,
        mentorName: mentor == null ? '-' : userDisplayName(mentor),
        studentCount: team?.studentIds.length ?? 0,
        coordinatorName: coordinator == null
            ? (payment.status == PaymentRecordStatus.pending ? 'Awaiting coordinator' : '-')
            : userDisplayName(coordinator),
        hasProof: hasProof,
        isOverdue: PaymentFinanceHelpers.isOverdue(payment),
        isRecentlyVerified: PaymentFinanceHelpers.isRecentlyVerified(payment),
        needsAttention: PaymentFinanceHelpers.needsAttention(payment, hasProof: hasProof),
      );
      contributions.add(contribution);

      var students = <UserModel>[];
      if (team != null) {
        for (final id in team.studentIds) {
          final student = userById[id];
          if (student != null) students.add(student);
        }
        students = sortUsersByDisplayName(students);
      }

      final double percent = summary.totalCollection <= 0
          ? 0.0
          : (payment.amount / summary.totalCollection * 100).clamp(0.0, 100.0).toDouble();

      detailsByPaymentId[payment.paymentId] = DepartmentPaymentDetail(
        contribution: contribution,
        idea: idea,
        team: team,
        problem: problem,
        students: students,
        proofAttachments: proof,
        departmentContributionPercent: percent,
        paymentTrendLabel: _trendLabel(payment),
      );
    }

    final workspace = DepartmentPaymentsWorkspace(
      summary: summary,
      contributions: contributions,
      detailsByPaymentId: detailsByPaymentId,
    );
    _cache[key] = workspace;
    _cacheAt[key] = DateTime.now();
    return workspace;
  }

  static DepartmentPaymentsSummary _buildSummary(List<PaymentModel> payments) {
    var verifiedAmount = 0.0;
    var pendingAmount = 0.0;
    var rejectedAmount = 0.0;
    var verifiedCount = 0;
    var pendingCount = 0;
    var rejectedCount = 0;

    for (final payment in payments) {
      switch (payment.status) {
        case PaymentRecordStatus.verified:
          verifiedCount++;
          verifiedAmount += payment.amount;
          break;
        case PaymentRecordStatus.rejected:
          rejectedCount++;
          rejectedAmount += payment.amount;
          break;
        case PaymentRecordStatus.pending:
          pendingCount++;
          pendingAmount += payment.amount;
          break;
      }
    }

    return DepartmentPaymentsSummary(
      totalCollection: verifiedAmount + pendingAmount + rejectedAmount,
      verifiedCount: verifiedCount,
      verifiedAmount: verifiedAmount,
      pendingCount: pendingCount,
      pendingAmount: pendingAmount,
      rejectedCount: rejectedCount,
      rejectedAmount: rejectedAmount,
    );
  }

  static String _ideaTitle(IdeaModel? idea) {
    if (idea == null) return 'Untitled Idea';
    final title = idea.ideaTitle.trim();
    return title.isEmpty ? 'Untitled Idea' : title;
  }

  static String _problemTitle(IdeaModel? idea, ProblemModel? problem, PaymentModel payment) {
    if (problem != null && problem.title.trim().isNotEmpty) return problem.title.trim();
    if (idea != null && idea.problemTitle.trim().isNotEmpty) return idea.problemTitle.trim();
    if (payment.problemNumber.trim().isNotEmpty) return payment.problemNumber.trim();
    return 'Problem';
  }

  static String _trendLabel(PaymentModel payment) {
    if (payment.status == PaymentRecordStatus.verified) return 'Verified in department';
    if (PaymentFinanceHelpers.isOverdue(payment)) return 'Attention: overdue verification';
    if (payment.status == PaymentRecordStatus.pending) return 'Awaiting coordinator action';
    return 'Rejected — resubmission may be required';
  }

  static List<DepartmentPaymentContribution> filterContributions({
    required List<DepartmentPaymentContribution> source,
    required String search,
    PaymentRecordStatus? status,
    DepartmentPaymentDateFilter dateFilter = DepartmentPaymentDateFilter.all,
    DepartmentPaymentVerificationFilter verificationFilter = DepartmentPaymentVerificationFilter.all,
  }) {
    final q = search.trim().toLowerCase();
    final now = DateTime.now();

    return source.where((item) {
      final payment = item.payment;
      if (status != null && payment.status != status) return false;

      switch (verificationFilter) {
        case DepartmentPaymentVerificationFilter.verifiedOnly:
          if (payment.status != PaymentRecordStatus.verified) return false;
          break;
        case DepartmentPaymentVerificationFilter.unverifiedOnly:
          if (payment.status == PaymentRecordStatus.verified) return false;
          break;
        case DepartmentPaymentVerificationFilter.all:
          break;
      }

      switch (dateFilter) {
        case DepartmentPaymentDateFilter.last7Days:
          if (now.difference(payment.createdAt).inDays > 7) return false;
          break;
        case DepartmentPaymentDateFilter.last30Days:
          if (now.difference(payment.createdAt).inDays > 30) return false;
          break;
        case DepartmentPaymentDateFilter.all:
          break;
      }

      if (q.isEmpty) return true;
      final haystack = <String>[
        item.ideaTitle,
        item.problemTitle,
        item.teamName,
        item.mentorName,
        payment.transactionId ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }
}
