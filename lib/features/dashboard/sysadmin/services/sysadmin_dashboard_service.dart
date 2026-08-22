import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../features/user/models/enums/user_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../../../../utils/firestore_utils.dart';

typedef _FirestoreDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

enum PlatformAnalyticsTimeframe {
  currentWeek('Current week'),
  lastWeek('Last week'),
  lastMonth('Last month'),
  lastSixMonths('Last 6 months'),
  all('All');

  const PlatformAnalyticsTimeframe(this.label);
  final String label;
}

class PlatformTrendPoint {
  const PlatformTrendPoint({
    required this.label,
    required this.users,
    required this.teams,
    required this.ideas,
    required this.evaluations,
  });

  final String label;
  final int users;
  final int teams;
  final int ideas;
  final int evaluations;
}

class InnovationFunnelStep {
  const InnovationFunnelStep({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class OrganizationActivityPoint {
  const OrganizationActivityPoint({
    required this.name,
    required this.activity,
    required this.activeDepartments,
  });

  final String name;
  final int activity;
  final int activeDepartments;
}

class PlatformAlert {
  const PlatformAlert({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final PlatformAlertSeverity severity;
}

enum PlatformAlertSeverity { info, warning, critical }

class PlatformActivityEvent {
  const PlatformActivityEvent({
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

class PlatformDistributionSegment {
  const PlatformDistributionSegment({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class SysAdminDashboardAnalytics {
  const SysAdminDashboardAnalytics({
    required this.activeOrganizations,
    required this.totalActiveUsers,
    required this.ideasSubmitted,
    required this.approvalRate,
    required this.trendsByTimeframe,
    required this.funnel,
    required this.organizationActivity,
    required this.alerts,
    required this.recentActivity,
    required this.usersByRole,
    required this.ideaStatusDistribution,
    required this.paymentVerificationRate,
  });

  final int activeOrganizations;
  final int totalActiveUsers;
  final int ideasSubmitted;
  final double approvalRate;
  final Map<PlatformAnalyticsTimeframe, List<PlatformTrendPoint>> trendsByTimeframe;
  final List<InnovationFunnelStep> funnel;
  final List<OrganizationActivityPoint> organizationActivity;
  final List<PlatformAlert> alerts;
  final List<PlatformActivityEvent> recentActivity;
  final List<PlatformDistributionSegment> usersByRole;
  final List<PlatformDistributionSegment> ideaStatusDistribution;
  final double paymentVerificationRate;

  List<PlatformTrendPoint> trendFor(PlatformAnalyticsTimeframe timeframe) {
    return trendsByTimeframe[timeframe] ?? const <PlatformTrendPoint>[];
  }
}

class SysAdminDashboardService {
  SysAdminDashboardService._();

  static SysAdminDashboardAnalytics? _cache;
  static DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  static void clearCache() {
    _cache = null;
    _cacheAt = null;
  }

  static bool isWithinTimeframe(DateTime when, PlatformAnalyticsTimeframe timeframe) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    switch (timeframe) {
      case PlatformAnalyticsTimeframe.currentWeek:
        final DateTime start = today.subtract(Duration(days: today.weekday - 1));
        final DateTime end = start.add(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(end);
      case PlatformAnalyticsTimeframe.lastWeek:
        final DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final DateTime start = currentWeekStart.subtract(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(currentWeekStart);
      case PlatformAnalyticsTimeframe.lastMonth:
        return !when.isBefore(today.subtract(const Duration(days: 30)));
      case PlatformAnalyticsTimeframe.lastSixMonths:
        return !when.isBefore(DateTime(today.year, today.month - 5, 1));
      case PlatformAnalyticsTimeframe.all:
        return true;
    }
  }

  static Future<SysAdminDashboardAnalytics> load({bool forceRefresh = false}) async {
    final cached = _cache;
    final cachedAt = _cacheAt;
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final results = await Future.wait<_FirestoreDocs>(<Future<_FirestoreDocs>>[
      _fetchCollection(FirestoreUtils.hkzOrganizations),
      _fetchCollection(FirestoreUtils.hkzUsers),
      _fetchCollection(FirestoreUtils.hkzTeams),
      _fetchCollection(FirestoreUtils.hkzIdeas),
      _fetchCollection(FirestoreUtils.hkzScores),
      _fetchCollection(FirestoreUtils.hkzProblems),
      _fetchCollection(FirestoreUtils.hkzPayments),
      _fetchCollection(FirestoreUtils.hkzFeedback),
    ]);

    final orgDocs = results[0];
    final userDocs = results[1];
    final teamDocs = results[2];
    final ideaDocs = results[3];
    final scoreDocs = results[4];
    final problemDocs = results[5];
    final paymentDocs = results[6];
    final feedbackDocs = results[7];

    final Map<String, String> orgNames = <String, String>{
      for (final doc in orgDocs) doc.id: ((doc.data()['name'] as String?) ?? doc.id).trim().isEmpty ? doc.id : ((doc.data()['name'] as String?) ?? doc.id).trim(),
    };

    final int activeUsers = userDocs.where((doc) => UserStatus.fromRaw((doc.data()['status'] as String?) ?? '') == UserStatus.active).length;
    final int approvedUsers = userDocs.where((doc) => UserStatus.fromRaw((doc.data()['status'] as String?) ?? '') == UserStatus.active).length;
    final double approvalRate = userDocs.isEmpty ? 0 : approvedUsers / userDocs.length;

    bool hasAggregate(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final data = doc.data();
      final totalEvaluators = (data[IdeaModel.fieldTotalEvaluators] as num?)?.toInt() ?? 0;
      final averageScore = data[IdeaModel.fieldAverageScore];
      return totalEvaluators > 0 && averageScore != null;
    }

    final int evaluatedIdeas = ideaDocs.where(hasAggregate).length;
    final int approvedIdeas = evaluatedIdeas;

    final List<OrganizationActivityPoint> orgActivity = _buildOrganizationActivity(
      orgDocs: orgDocs,
      userDocs: userDocs,
      teamDocs: teamDocs,
      ideaDocs: ideaDocs,
      scoreDocs: scoreDocs,
      orgNames: orgNames,
    );

    final int activeOrganizations = orgActivity.where((o) => o.activity > 0).length;
    final List<PaymentRecordStatus> paymentStatuses = paymentDocs.map((doc) => PaymentRecordStatus.fromRaw((doc.data()['status'] as String?) ?? '')).toList(growable: false);
    final int verifiedPayments = paymentStatuses.where((s) => s == PaymentRecordStatus.verified).length;

    final analytics = SysAdminDashboardAnalytics(
      activeOrganizations: activeOrganizations,
      totalActiveUsers: activeUsers,
      ideasSubmitted: ideaDocs.length,
      approvalRate: approvalRate,
      trendsByTimeframe: <PlatformAnalyticsTimeframe, List<PlatformTrendPoint>>{
        for (final PlatformAnalyticsTimeframe timeframe in PlatformAnalyticsTimeframe.values)
          timeframe: _buildTrend(userDocs, teamDocs, ideaDocs, scoreDocs, timeframe),
      },
      funnel: <InnovationFunnelStep>[
        InnovationFunnelStep(label: 'Problems', count: problemDocs.length, color: const Color(0xFF2563EB)),
        InnovationFunnelStep(label: 'Teams', count: teamDocs.length, color: const Color(0xFF7C3AED)),
        InnovationFunnelStep(label: 'Ideas', count: ideaDocs.length, color: const Color(0xFFEA580C)),
        InnovationFunnelStep(label: 'Evaluated', count: evaluatedIdeas, color: const Color(0xFF0891B2)),
        InnovationFunnelStep(label: 'Approved', count: approvedIdeas, color: const Color(0xFF16A34A)),
      ],
      organizationActivity: orgActivity,
      alerts: _buildAlerts(
        orgDocs: orgDocs,
        userDocs: userDocs,
        teamDocs: teamDocs,
        ideaDocs: ideaDocs,
        paymentDocs: paymentDocs,
        feedbackDocs: feedbackDocs,
      ),
      recentActivity: _buildRecentActivity(orgDocs, userDocs, problemDocs, scoreDocs, paymentDocs),
      usersByRole: _roleDistribution(userDocs),
      ideaStatusDistribution: _ideaStatusDistribution(ideaDocs),
      paymentVerificationRate: paymentDocs.isEmpty ? 0 : verifiedPayments / paymentDocs.length,
    );

    _cache = analytics;
    _cacheAt = DateTime.now();
    return analytics;
  }

  static Future<_FirestoreDocs> _fetchCollection(String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return snap.docs;
  }

  static List<PlatformTrendPoint> _buildTrend(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teams,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> ideas,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> scores,
    PlatformAnalyticsTimeframe timeframe,
  ) {
    final now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    late final DateTime start;
    late final DateTime end;
    late final int bucketCount;
    late final Duration bucketSize;

    switch (timeframe) {
      case PlatformAnalyticsTimeframe.currentWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case PlatformAnalyticsTimeframe.lastWeek:
        final DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        start = currentWeekStart.subtract(const Duration(days: 7));
        end = currentWeekStart;
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case PlatformAnalyticsTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
        break;
      case PlatformAnalyticsTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
        break;
      case PlatformAnalyticsTimeframe.all:
        final List<DateTime> dates = <DateTime?>[
          ...users.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...teams.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...ideas.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...scores.map((doc) => _dateFrom(doc.data()['createdAt'])),
        ].whereType<DateTime>().toList(growable: false);
        start = dates.isEmpty ? today.subtract(const Duration(days: 180)) : _monthStart(dates.reduce((a, b) => a.isBefore(b) ? a : b));
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final int days = end.difference(start).inDays.clamp(1, 3650);
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365));
        break;
    }

    final List<DateTime> buckets = List<DateTime>.generate(
      bucketCount,
      (int i) => start.add(Duration(days: bucketSize.inDays * i)),
    );

    int countInBucket(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, int i) {
      final DateTime from = buckets[i];
      final DateTime to = i == buckets.length - 1 ? end : buckets[i + 1];
      return docs.where((doc) {
        final created = _dateFrom(doc.data()['createdAt']);
        return created != null && !created.isBefore(from) && created.isBefore(to);
      }).length;
    }

    return List<PlatformTrendPoint>.generate(buckets.length, (int i) {
      final b = buckets[i];
      return PlatformTrendPoint(
        label: _bucketLabel(b, timeframe),
        users: countInBucket(users, i),
        teams: countInBucket(teams, i),
        ideas: countInBucket(ideas, i),
        evaluations: countInBucket(scores, i),
      );
    });
  }

  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  static String _bucketLabel(DateTime date, PlatformAnalyticsTimeframe timeframe) {
    switch (timeframe) {
      case PlatformAnalyticsTimeframe.currentWeek:
      case PlatformAnalyticsTimeframe.lastWeek:
        const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case PlatformAnalyticsTimeframe.lastSixMonths:
      case PlatformAnalyticsTimeframe.all:
        const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
      case PlatformAnalyticsTimeframe.lastMonth:
        return '${date.month}/${date.day}';
    }
  }

  static List<OrganizationActivityPoint> _buildOrganizationActivity({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orgDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> teamDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> ideaDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> scoreDocs,
    required Map<String, String> orgNames,
  }) {
    final Map<String, int> activity = <String, int>{for (final doc in orgDocs) doc.id: 0};
    final Map<String, Set<String>> departments = <String, Set<String>>{for (final doc in orgDocs) doc.id: <String>{}};

    void add(QueryDocumentSnapshot<Map<String, dynamic>> doc, {int weight = 1}) {
      final data = doc.data();
      final orgId = ((data['orgId'] as String?) ?? '').trim();
      if (orgId.isEmpty) return;
      activity[orgId] = (activity[orgId] ?? 0) + weight;
      final dept = ((data['departmentCode'] as String?) ?? '').trim().toUpperCase();
      if (dept.isNotEmpty) {
        departments.putIfAbsent(orgId, () => <String>{}).add(dept);
      }
    }

    for (final doc in userDocs) {
      add(doc);
    }
    for (final doc in teamDocs) {
      add(doc, weight: 2);
    }
    for (final doc in ideaDocs) {
      add(doc, weight: 3);
    }
    for (final doc in scoreDocs) {
      add(doc, weight: 2);
    }

    return activity.entries
        .map((entry) => OrganizationActivityPoint(
              name: orgNames[entry.key] ?? entry.key,
              activity: entry.value,
              activeDepartments: departments[entry.key]?.length ?? 0,
            ))
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static List<PlatformAlert> _buildAlerts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orgDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> teamDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> ideaDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> paymentDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> feedbackDocs,
  }) {
    final List<PlatformAlert> alerts = <PlatformAlert>[];
    final int pendingUsers = userDocs.where((doc) => UserStatus.fromRaw((doc.data()['status'] as String?) ?? '') == UserStatus.pendingApproval).length;
    if (pendingUsers > 0 && pendingUsers / userDocs.length.clamp(1, 1 << 31) >= 0.2) {
      alerts.add(PlatformAlert(
        title: 'Pending approvals spike',
        message: '$pendingUsers account requests need admin attention.',
        severity: PlatformAlertSeverity.warning,
      ));
    }

    final DateTime staleCutoff = DateTime.now().subtract(const Duration(days: 14));
    final Set<String> activeOrgIds = <String>{};
    for (final docs in <List<QueryDocumentSnapshot<Map<String, dynamic>>>>[userDocs, teamDocs, ideaDocs]) {
      for (final doc in docs) {
        final created = _dateFrom(doc.data()['createdAt']);
        final orgId = ((doc.data()['orgId'] as String?) ?? '').trim();
        if (orgId.isNotEmpty && created != null && created.isAfter(staleCutoff)) {
          activeOrgIds.add(orgId);
        }
      }
    }
    final int inactiveOrgs = orgDocs.where((doc) => !activeOrgIds.contains(doc.id)).length;
    if (inactiveOrgs > 0) {
      alerts.add(PlatformAlert(
        title: 'Inactive organizations',
        message: '$inactiveOrgs organizations have no recent activity in the last 14 days.',
        severity: PlatformAlertSeverity.info,
      ));
    }

    final DateTime evaluationCutoff = DateTime.now().subtract(const Duration(days: 7));
    final int delayedEvaluations = ideaDocs.where((doc) {
      final status = IdeaStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      final created = _dateFrom(doc.data()['createdAt']);
      return created != null && created.isBefore(evaluationCutoff) && status == IdeaStatus.submitted;
    }).length;
    if (delayedEvaluations > 0) {
      alerts.add(PlatformAlert(
        title: 'Evaluation delays',
        message: '$delayedEvaluations submitted ideas are waiting more than 7 days.',
        severity: PlatformAlertSeverity.warning,
      ));
    }

    final int paymentBacklog = paymentDocs.where((doc) => PaymentRecordStatus.fromRaw((doc.data()['status'] as String?) ?? '') == PaymentRecordStatus.pending).length;
    if (paymentBacklog > 0) {
      alerts.add(PlatformAlert(
        title: 'Payment verification backlog',
        message: '$paymentBacklog payments are pending coordinator verification.',
        severity: paymentBacklog > 10 ? PlatformAlertSeverity.critical : PlatformAlertSeverity.warning,
      ));
    }

    final int openFeedback = feedbackDocs.where((doc) {
      final String status = ((doc.data()['status'] as String?) ?? '').trim().toUpperCase();
      return status == 'OPEN';
    }).length;
    if (openFeedback > 0) {
      alerts.add(PlatformAlert(
        title: 'Open feedback',
        message: '$openFeedback feedback item${openFeedback == 1 ? '' : 's'} awaiting review.',
        severity: openFeedback > 20 ? PlatformAlertSeverity.warning : PlatformAlertSeverity.info,
      ));
    }

    if (alerts.isEmpty) {
      alerts.add(const PlatformAlert(
        title: 'Platform health looks steady',
        message: 'No operational issues crossed alert thresholds.',
        severity: PlatformAlertSeverity.info,
      ));
    }
    return alerts;
  }

  static List<PlatformActivityEvent> _buildRecentActivity(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> orgDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> problemDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> scoreDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> paymentDocs,
  ) {
    final List<PlatformActivityEvent> events = <PlatformActivityEvent>[];
    for (final doc in orgDocs) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(PlatformActivityEvent(
        title: 'Organization onboarded',
        subtitle: ((data['name'] as String?) ?? doc.id).trim(),
        when: when,
        icon: Icons.apartment_outlined,
        tint: const Color(0xFF2563EB),
      ));
    }
    for (final doc in userDocs) {
      final data = doc.data();
      final role = ((data['role'] as String?) ?? '').trim().toUpperCase();
      if (role != 'DADM') continue;
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(PlatformActivityEvent(
        title: 'Department admin added',
        subtitle: '${((data['firstName'] as String?) ?? '').trim()} ${((data['lastName'] as String?) ?? '').trim()}'.trim(),
        when: when,
        icon: Icons.manage_accounts_outlined,
        tint: const Color(0xFF7C3AED),
      ));
    }
    for (final doc in problemDocs) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(PlatformActivityEvent(
        title: 'Problem created',
        subtitle: ((data['title'] as String?) ?? 'New problem').trim(),
        when: when,
        icon: Icons.assignment_outlined,
        tint: const Color(0xFFEA580C),
      ));
    }
    for (final doc in scoreDocs) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(PlatformActivityEvent(
        title: 'Evaluation completed',
        subtitle: 'Idea ${((data['ideaId'] as String?) ?? '').trim()}',
        when: when,
        icon: Icons.fact_check_outlined,
        tint: const Color(0xFF0891B2),
      ));
    }
    for (final doc in paymentDocs) {
      final data = doc.data();
      final status = PaymentRecordStatus.fromRaw((data['status'] as String?) ?? '');
      if (status != PaymentRecordStatus.verified) continue;
      final when = _dateFrom(data['verifiedAt']) ?? _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(PlatformActivityEvent(
        title: 'Payment approved',
        subtitle: 'Problem ${((data['problemNumber'] as String?) ?? '').trim()}',
        when: when,
        icon: Icons.verified_outlined,
        tint: const Color(0xFF16A34A),
      ));
    }
    events.sort((a, b) => b.when.compareTo(a.when));
    return events.take(80).toList(growable: false);
  }

  static List<PlatformDistributionSegment> _roleDistribution(List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs) {
    const colors = <Color>[
      Color(0xFF6A38FF),
      Color(0xFF0EA5E9),
      Color(0xFF16A34A),
      Color(0xFFEA580C),
      Color(0xFFDB2777),
      Color(0xFF64748B),
    ];
    final Map<String, int> counts = <String, int>{};
    for (final doc in userDocs) {
      final role = ((doc.data()['role'] as String?) ?? 'UNK').trim().toUpperCase();
      counts[role.isEmpty ? 'UNK' : role] = (counts[role.isEmpty ? 'UNK' : role] ?? 0) + 1;
    }
    int i = 0;
    return counts.entries.map((e) {
      final segment = PlatformDistributionSegment(label: _roleLabel(e.key), count: e.value, color: colors[i % colors.length]);
      i++;
      return segment;
    }).toList(growable: false);
  }

  static List<PlatformDistributionSegment> _ideaStatusDistribution(_FirestoreDocs ideaDocs) {
    int draft = 0;
    int submitted = 0;
    int scored = 0;
    for (final doc in ideaDocs) {
      final data = doc.data();
      final status = IdeaStatus.fromRaw((data['status'] as String?) ?? '');
      if (status == IdeaStatus.draft) {
        draft++;
        continue;
      }
      submitted++;
      final totalEvaluators = (data[IdeaModel.fieldTotalEvaluators] as num?)?.toInt() ?? 0;
      final averageScore = data[IdeaModel.fieldAverageScore];
      if (totalEvaluators > 0 && averageScore != null) scored++;
    }
    return <PlatformDistributionSegment>[
      PlatformDistributionSegment(label: 'Draft', count: draft, color: const Color(0xFF94A3B8)),
      PlatformDistributionSegment(label: 'Submitted', count: submitted, color: const Color(0xFF2563EB)),
      PlatformDistributionSegment(label: 'Scored', count: scored, color: const Color(0xFF0891B2)),
    ];
  }

  static String _roleLabel(String code) {
    switch (code) {
      case 'SADM':
        return 'SysAdmin';
      case 'CADM':
        return 'College admins';
      case 'DADM':
        return 'Dept admins';
      case 'FAC':
        return 'Faculty';
      case 'JUD':
        return 'Judges';
      case 'COO':
        return 'Coordinators';
      case 'TMEM':
        return 'Team Members';
      default:
        return code;
    }
  }

  static DateTime? _dateFrom(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
