import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/attachment_model.dart';
import '../models/enums/user_role.dart';
import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../features/team/models/team_model.dart';
import '../models/user_model.dart';
import 'firestore_utils.dart';
import 'role_visibility_helpers.dart';

typedef _FirestoreDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

enum CoordinatorDashboardTimeframe {
  currentWeek('Current week'),
  lastMonth('Last month'),
  lastSixMonths('Last 6 months'),
  all('All');

  const CoordinatorDashboardTimeframe(this.label);
  final String label;
}

class CoordinatorTrendPoint {
  const CoordinatorTrendPoint({
    required this.label,
    required this.submitted,
    required this.verified,
    required this.rejected,
  });

  final String label;
  final int submitted;
  final int verified;
  final int rejected;
}

class SubmissionWorkflowStep {
  const SubmissionWorkflowStep({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class PaymentQueueItem {
  const PaymentQueueItem({
    required this.payment,
    required this.teamName,
    required this.problemName,
    required this.hasProof,
    required this.isOverdue,
    required this.submittedAt,
  });

  final PaymentModel payment;
  final String teamName;
  final String problemName;
  final bool hasProof;
  final bool isOverdue;
  final DateTime submittedAt;
}

class CoordinatorEscalation {
  const CoordinatorEscalation({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final CoordinatorEscalationSeverity severity;
}

enum CoordinatorEscalationSeverity { info, warning, critical }

class CoordinatorActivityItem {
  const CoordinatorActivityItem({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final DateTime when;
  final IconData icon;
  final Color tint;
}

class DepartmentOperationalSnapshotVm {
  const DepartmentOperationalSnapshotVm({
    required this.ideasAwaitingPayment,
    required this.blockedTeams,
    required this.verificationCompletion,
    required this.activeSubmissionWindow,
  });

  final int ideasAwaitingPayment;
  final int blockedTeams;
  final double verificationCompletion;
  final String activeSubmissionWindow;
}

class CoordinatorDashboardAnalytics {
  const CoordinatorDashboardAnalytics({
    required this.pendingPayments,
    required this.verifiedPaymentsToday,
    required this.ideasAwaitingValidation,
    required this.rejectedPayments,
    required this.trendsByTimeframe,
    required this.workflow,
    required this.pendingQueue,
    required this.escalations,
    required this.snapshot,
    required this.recentActivity,
  });

  final int pendingPayments;
  final int verifiedPaymentsToday;
  final int ideasAwaitingValidation;
  final int rejectedPayments;
  final Map<CoordinatorDashboardTimeframe, List<CoordinatorTrendPoint>> trendsByTimeframe;
  final List<SubmissionWorkflowStep> workflow;
  final List<PaymentQueueItem> pendingQueue;
  final List<CoordinatorEscalation> escalations;
  final DepartmentOperationalSnapshotVm snapshot;
  final List<CoordinatorActivityItem> recentActivity;

  List<CoordinatorTrendPoint> trendFor(CoordinatorDashboardTimeframe timeframe) {
    return trendsByTimeframe[timeframe] ?? const <CoordinatorTrendPoint>[];
  }
}

class CoordinatorDashboardService {
  CoordinatorDashboardService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final Map<String, CoordinatorDashboardAnalytics> _cache = <String, CoordinatorDashboardAnalytics>{};
  static final Map<String, DateTime> _cacheAt = <String, DateTime>{};
  static const Duration _cacheTtl = Duration(minutes: 3);
  static const Duration _overdueThreshold = Duration(hours: 48);

  static void clearCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  static String _cacheKey(UserModel user) => '${user.orgId}::${user.departmentCode.trim().toUpperCase()}';

  static Future<CoordinatorDashboardAnalytics> load(UserModel user, {bool forceRefresh = false}) async {
    final key = _cacheKey(user);
    final cached = _cache[key];
    final cachedAt = _cacheAt[key];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final results = await Future.wait<_FirestoreDocs>(<Future<_FirestoreDocs>>[
      _fetchOrg(FirestoreUtils.hkzPayments, user.orgId),
      _fetchOrg(FirestoreUtils.hkzIdeas, user.orgId),
      _fetchOrg(FirestoreUtils.hkzTeams, user.orgId),
      _fetchOrg(FirestoreUtils.hkzAttachments, user.orgId),
      _fetchOrg(FirestoreUtils.hkzScores, user.orgId),
    ]);

    final dept = user.departmentCode.trim().toUpperCase();
    bool inFinanceDept(Map<String, dynamic> data) =>
        dept.isEmpty || ((data['departmentCode'] as String?) ?? '').trim().toUpperCase() == dept;

    final payments = results[0]
        .where((doc) => inFinanceDept(doc.data()))
        .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paymentTeamIds = payments.map((p) => p.teamId.trim()).where((id) => id.isNotEmpty).toSet();
    final ideas = results[1]
        .where((doc) => RoleVisibilityHelpers.ideaMapVisibleToUser(doc.data(), user))
        .map((doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final teams = results[2]
        .where((doc) => paymentTeamIds.contains(doc.id))
        .map((doc) => TeamModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final attachments = results[3]
        .where((doc) => RoleVisibilityHelpers.paymentMapVisibleToCoordinator(doc.data(), user))
        .map((doc) => AttachmentModel.fromMap(doc.id, doc.data()))
        .where((attachment) => attachment.isActive && attachment.entityType == AttachmentEntityType.payment)
        .toList(growable: false);
    final scopedIdeaIds = ideas.map((idea) => idea.ideaId).toSet();
    final scores = results[4]
        .where((doc) => scopedIdeaIds.contains(((doc.data()['ideaId'] as String?) ?? '').trim()))
        .toList(growable: false);

    final paymentByIdea = <String, PaymentModel>{for (final payment in payments) payment.ideaId: payment};
    final teamNameById = <String, String>{for (final team in teams) team.teamId: team.teamName.isEmpty ? team.teamId : team.teamName};
    final ideaById = <String, IdeaModel>{for (final idea in ideas) idea.ideaId: idea};
    final attachmentsByPayment = <String, List<AttachmentModel>>{};
    for (final attachment in attachments) {
      attachmentsByPayment.putIfAbsent(attachment.entityId, () => <AttachmentModel>[]).add(attachment);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final verifiedToday = payments.where((payment) {
      final verifiedAt = payment.verifiedAt;
      return payment.status == PaymentRecordStatus.verified && verifiedAt != null && !verifiedAt.isBefore(today);
    }).length;

    final pendingQueue = payments
        .where((payment) => payment.status == PaymentRecordStatus.pending)
        .map((payment) {
          final idea = ideaById[payment.ideaId];
          final hasProof = payment.paymentProofUrl.trim().isNotEmpty || (attachmentsByPayment[payment.paymentId]?.isNotEmpty ?? false);
          return PaymentQueueItem(
            payment: payment,
            teamName: teamNameById[payment.teamId] ?? payment.teamId,
            problemName: idea?.problemTitle.trim().isNotEmpty == true ? idea!.problemTitle : (payment.problemNumber.isEmpty ? payment.problemId : payment.problemNumber),
            hasProof: hasProof,
            isOverdue: now.difference(payment.createdAt) > _overdueThreshold,
            submittedAt: payment.createdAt,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

    final pendingPayments = pendingQueue.length;
    final rejectedPayments = payments.where((payment) => payment.status == PaymentRecordStatus.rejected).length;
    final verifiedPayments = payments.where((payment) => payment.status == PaymentRecordStatus.verified).length;
    final ideasAwaitingValidation = ideas.where((idea) {
      final payment = paymentByIdea[idea.ideaId];
      return idea.status == IdeaStatus.pendingSubmission && payment != null && payment.status == PaymentRecordStatus.pending;
    }).length;
    final ideasAwaitingPayment = ideas.where((idea) => idea.status == IdeaStatus.pendingSubmission && paymentByIdea[idea.ideaId] == null).length;
    final blockedTeams = payments.where((payment) => payment.status != PaymentRecordStatus.verified).map((payment) => payment.teamId).where((id) => id.isNotEmpty).toSet().length;

    final analytics = CoordinatorDashboardAnalytics(
      pendingPayments: pendingPayments,
      verifiedPaymentsToday: verifiedToday,
      ideasAwaitingValidation: ideasAwaitingValidation,
      rejectedPayments: rejectedPayments,
      trendsByTimeframe: <CoordinatorDashboardTimeframe, List<CoordinatorTrendPoint>>{
        for (final timeframe in CoordinatorDashboardTimeframe.values) timeframe: _buildTrend(payments, timeframe),
      },
      workflow: _buildWorkflow(ideas, payments, paymentOnly: !RoleVisibilityHelpers.canViewIdeas(UserRole.fromCode(user.role))),
      pendingQueue: pendingQueue,
      escalations: _buildEscalations(pendingQueue, payments),
      snapshot: DepartmentOperationalSnapshotVm(
        ideasAwaitingPayment: ideasAwaitingPayment,
        blockedTeams: blockedTeams,
        verificationCompletion: payments.isEmpty ? 0.0 : verifiedPayments / payments.length,
        activeSubmissionWindow: pendingPayments == 0 ? 'Clear' : '$pendingPayments payments in queue',
      ),
      recentActivity: _buildActivity(payments, scores),
    );

    _cache[key] = analytics;
    _cacheAt[key] = DateTime.now();
    return analytics;
  }

  static Future<void> verifyPayment({required PaymentModel payment, required UserModel coordinator}) async {
    await FirestoreUtils.verifyIdeaPayment(paymentId: payment.paymentId, coordinatorId: coordinator.userId);
    clearCache();
  }

  static Future<void> rejectPayment({required PaymentModel payment, required UserModel coordinator, String? remarks}) async {
    await FirestoreUtils.rejectIdeaPayment(paymentId: payment.paymentId, coordinatorId: coordinator.userId, remarks: remarks);
    clearCache();
  }

  static Future<_FirestoreDocs> _fetchOrg(String collection, String orgId) async {
    final snap = await _db.collection(collection).where('orgId', isEqualTo: orgId).get();
    return snap.docs;
  }

  static List<SubmissionWorkflowStep> _buildWorkflow(
    List<IdeaModel> ideas,
    List<PaymentModel> payments, {
    required bool paymentOnly,
  }) {
    final pending = payments.where((payment) => payment.status == PaymentRecordStatus.pending).length;
    final approved = payments.where((payment) => payment.status == PaymentRecordStatus.verified).length;
    final rejected = payments.where((payment) => payment.status == PaymentRecordStatus.rejected).length;
    if (paymentOnly) {
      return <SubmissionWorkflowStep>[
        SubmissionWorkflowStep(label: 'Payments Submitted', count: payments.length, color: const Color(0xFF0EA5E9)),
        SubmissionWorkflowStep(label: 'Verification Pending', count: pending, color: const Color(0xFFF59E0B)),
        SubmissionWorkflowStep(label: 'Payment Approved', count: approved, color: const Color(0xFF16A34A)),
        SubmissionWorkflowStep(label: 'Payment Rejected', count: rejected, color: const Color(0xFFDC2626)),
      ];
    }
    final paymentsByIdea = <String, PaymentModel>{for (final payment in payments) payment.ideaId: payment};
    final paymentSubmitted = ideas.where((idea) => paymentsByIdea.containsKey(idea.ideaId)).length;
    final official = ideas.where((idea) => idea.status == IdeaStatus.submitted || idea.status == IdeaStatus.underReview || idea.status == IdeaStatus.evaluated || idea.status == IdeaStatus.approved).length;
    return <SubmissionWorkflowStep>[
      SubmissionWorkflowStep(label: 'Ideas Created', count: ideas.length, color: const Color(0xFF6A38FF)),
      SubmissionWorkflowStep(label: 'Payment Submitted', count: paymentSubmitted, color: const Color(0xFF0EA5E9)),
      SubmissionWorkflowStep(label: 'Verification Pending', count: pending, color: const Color(0xFFF59E0B)),
      SubmissionWorkflowStep(label: 'Payment Approved', count: approved, color: const Color(0xFF16A34A)),
      SubmissionWorkflowStep(label: 'Officially Submitted', count: official, color: const Color(0xFF0891B2)),
    ];
  }

  static List<CoordinatorEscalation> _buildEscalations(List<PaymentQueueItem> queue, List<PaymentModel> payments) {
    final overdue = queue.where((item) => item.isOverdue).length;
    final missingProof = queue.where((item) => !item.hasProof).length;
    final rejected = payments.where((payment) => payment.status == PaymentRecordStatus.rejected).length;
    final repeated = <String, int>{};
    for (final payment in payments.where((payment) => payment.status == PaymentRecordStatus.rejected)) {
      repeated[payment.ideaId] = (repeated[payment.ideaId] ?? 0) + 1;
    }
    final repeatedCount = repeated.values.where((count) => count > 1).length;
    final alerts = <CoordinatorEscalation>[
      if (overdue > 0) CoordinatorEscalation(title: 'Delayed payment reviews', message: '$overdue payments have been pending for more than 48 hours.', severity: CoordinatorEscalationSeverity.critical),
      if (missingProof > 0) CoordinatorEscalation(title: 'Missing proof uploads', message: '$missingProof pending payments do not have a screenshot or attachment.', severity: CoordinatorEscalationSeverity.warning),
      if (rejected > 0) CoordinatorEscalation(title: 'Failed verifications', message: '$rejected payments were rejected and may need follow-up.', severity: CoordinatorEscalationSeverity.warning),
      if (repeatedCount > 0) CoordinatorEscalation(title: 'Repeated resubmissions', message: '$repeatedCount submissions have repeated payment rejection history.', severity: CoordinatorEscalationSeverity.critical),
    ];
    if (alerts.isEmpty) {
      alerts.add(const CoordinatorEscalation(title: 'Queue health looks clear', message: 'No escalation thresholds are currently crossed.', severity: CoordinatorEscalationSeverity.info));
    }
    return alerts;
  }

  static List<CoordinatorActivityItem> _buildActivity(List<PaymentModel> payments, _FirestoreDocs scores) {
    final items = <CoordinatorActivityItem>[];
    for (final payment in payments) {
      if (payment.status == PaymentRecordStatus.verified && payment.verifiedAt != null) {
        items.add(CoordinatorActivityItem(title: 'Payment verified', subtitle: payment.problemNumber.isEmpty ? payment.ideaId : payment.problemNumber, when: payment.verifiedAt!, icon: AppIcons.verification, tint: const Color(0xFF16A34A)));
      } else if (payment.status == PaymentRecordStatus.rejected) {
        items.add(CoordinatorActivityItem(title: 'Payment rejected / idea unlocked', subtitle: payment.problemNumber.isEmpty ? payment.ideaId : payment.problemNumber, when: payment.verifiedAt ?? payment.createdAt, icon: AppIcons.statusRejected, tint: const Color(0xFFDC2626)));
      }
    }
    for (final doc in scores) {
      final data = doc.data();
      final createdAt = _dateFrom(data['createdAt']);
      if (createdAt == null) continue;
      items.add(CoordinatorActivityItem(title: 'Submission validated', subtitle: ((data['ideaId'] as String?) ?? '').trim(), when: createdAt, icon: AppIcons.scoring, tint: const Color(0xFF0891B2)));
    }
    items.sort((a, b) => b.when.compareTo(a.when));
    return items.take(20).toList(growable: false);
  }

  static List<CoordinatorTrendPoint> _buildTrend(List<PaymentModel> payments, CoordinatorDashboardTimeframe timeframe) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late final DateTime start;
    late final DateTime end;
    late final int bucketCount;
    late final Duration bucketSize;
    switch (timeframe) {
      case CoordinatorDashboardTimeframe.currentWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
      case CoordinatorDashboardTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
      case CoordinatorDashboardTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
      case CoordinatorDashboardTimeframe.all:
        final dates = payments.map((payment) => payment.createdAt).toList(growable: false)..sort();
        start = dates.isEmpty ? today.subtract(const Duration(days: 180)) : DateTime(dates.first.year, dates.first.month, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final days = end.difference(start).inDays.clamp(1, 3650).toInt();
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365).toInt());
    }
    final buckets = List<DateTime>.generate(bucketCount, (i) => start.add(Duration(days: bucketSize.inDays * i)));
    return List<CoordinatorTrendPoint>.generate(buckets.length, (i) {
      final from = buckets[i];
      final to = i == buckets.length - 1 ? end : buckets[i + 1];
      bool inBucket(DateTime date) => !date.isBefore(from) && date.isBefore(to);
      return CoordinatorTrendPoint(
        label: _bucketLabel(from, timeframe),
        submitted: payments.where((payment) => inBucket(payment.createdAt)).length,
        verified: payments.where((payment) => payment.status == PaymentRecordStatus.verified && payment.verifiedAt != null && inBucket(payment.verifiedAt!)).length,
        rejected: payments.where((payment) => payment.status == PaymentRecordStatus.rejected && inBucket(payment.verifiedAt ?? payment.createdAt)).length,
      );
    });
  }

  static String _bucketLabel(DateTime date, CoordinatorDashboardTimeframe timeframe) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    switch (timeframe) {
      case CoordinatorDashboardTimeframe.currentWeek:
        const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case CoordinatorDashboardTimeframe.lastMonth:
        return '${date.month}/${date.day}';
      case CoordinatorDashboardTimeframe.lastSixMonths:
        return months[date.month - 1];
      case CoordinatorDashboardTimeframe.all:
        return '${months[date.month - 1]} ${date.year % 100}';
    }
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
