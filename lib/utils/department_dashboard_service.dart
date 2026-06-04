import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../features/organization/models/department_model.dart';
import '../features/user/models/enums/user_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import 'firestore_utils.dart';
import '../features/idea/services/idea_department_helpers.dart';

typedef _FirestoreDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

enum DepartmentAnalyticsTimeframe {
  currentWeek('Current week'),
  lastWeek('Last week'),
  lastMonth('Last month'),
  lastSixMonths('Last 6 months'),
  all('All');

  const DepartmentAnalyticsTimeframe(this.label);
  final String label;
}

class DepartmentTrendPoint {
  const DepartmentTrendPoint({
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

class DepartmentDistributionSegment {
  const DepartmentDistributionSegment({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class DepartmentProblemPreview {
  const DepartmentProblemPreview({
    required this.problemId,
    required this.title,
    required this.ideaCount,
  });

  final String problemId;
  final String title;
  final int ideaCount;
}

class DepartmentIdeaPreview {
  const DepartmentIdeaPreview({
    required this.ideaId,
    required this.title,
    required this.status,
  });

  final String ideaId;
  final String title;
  final IdeaStatus status;
}

class DepartmentAlert {
  const DepartmentAlert({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final DepartmentAlertSeverity severity;
}

enum DepartmentAlertSeverity { info, warning, critical }

class DepartmentActivityEvent {
  const DepartmentActivityEvent({
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

class DepartmentDashboardAnalytics {
  const DepartmentDashboardAnalytics({
    required this.totalActiveUsers,
    required this.pendingApprovals,
    required this.activeProblems,
    required this.ideasSubmitted,
    required this.facultyCount,
    required this.studentCount,
    required this.coordinatorCount,
    required this.judgeCount,
    required this.pendingCoordinatorJudgeCount,
    required this.pendingPayments,
    required this.pendingSubmissionIdeas,
    required this.underReviewIdeas,
    required this.submittedIdeas,
    required this.evaluatedOnlyIdeas,
    required this.evaluatedIdeas,
    required this.approvedIdeas,
    required this.rejectedIdeas,
    required this.trendsByTimeframe,
    required this.usersByRole,
    required this.departmentProblems,
    required this.departmentIdeas,
    required this.alerts,
    required this.recentActivity,
    required this.paymentVerificationRate,
    required this.evaluationCompletionRate,
  });

  final int totalActiveUsers;
  final int pendingApprovals;
  final int activeProblems;
  final int ideasSubmitted;
  final int facultyCount;
  final int studentCount;
  final int coordinatorCount;
  final int judgeCount;
  final int pendingCoordinatorJudgeCount;
  final int pendingPayments;
  final int pendingSubmissionIdeas;
  final int underReviewIdeas;
  final int submittedIdeas;
  final int evaluatedOnlyIdeas;
  final int evaluatedIdeas;
  final int approvedIdeas;
  final int rejectedIdeas;
  final Map<DepartmentAnalyticsTimeframe, List<DepartmentTrendPoint>> trendsByTimeframe;
  final List<DepartmentDistributionSegment> usersByRole;
  final List<DepartmentProblemPreview> departmentProblems;
  final List<DepartmentIdeaPreview> departmentIdeas;
  final List<DepartmentAlert> alerts;
  final List<DepartmentActivityEvent> recentActivity;
  final double paymentVerificationRate;
  final double evaluationCompletionRate;

  List<DepartmentTrendPoint> trendFor(DepartmentAnalyticsTimeframe timeframe) {
    return trendsByTimeframe[timeframe] ?? const <DepartmentTrendPoint>[];
  }
}

class DepartmentDashboardService {
  DepartmentDashboardService._();

  static final Map<String, DepartmentDashboardAnalytics> _cache = <String, DepartmentDashboardAnalytics>{};
  static final Map<String, DateTime> _cacheAt = <String, DateTime>{};
  static const Duration _cacheTtl = Duration(minutes: 5);

  static void clearCache() {
    _cache.clear();
    _cacheAt.clear();
  }

  static Future<DepartmentDashboardAnalytics> load({
    required String orgId,
    required String departmentCode,
    bool forceRefresh = false,
  }) async {
    final String dept = DepartmentModel.resolveCode(departmentCode);
    final String cacheKey = '$orgId::$dept';
    final cached = _cache[cacheKey];
    final cachedAt = _cacheAt[cacheKey];
    if (!forceRefresh && cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    final results = await Future.wait<_FirestoreDocs>(<Future<_FirestoreDocs>>[
      _fetchOrgCollection(FirestoreUtils.hkzUsers, orgId),
      _fetchOrgCollection(FirestoreUtils.hkzTeams, orgId),
      _fetchOrgCollection(FirestoreUtils.hkzIdeas, orgId),
      _fetchOrgCollection(FirestoreUtils.hkzScores, orgId),
      _fetchOrgCollection(FirestoreUtils.hkzProblems, orgId),
      _fetchOrgCollection(FirestoreUtils.hkzPayments, orgId),
    ]);

    final users = results[0].where((doc) => _matchesDept(doc.data(), dept)).toList(growable: false);
    final teams = results[1].where((doc) => _matchesDept(doc.data(), dept)).toList(growable: false);
    final ideas = results[2].where((doc) => IdeaDepartmentHelpers.matchesTeamDept(doc.data(), dept)).toList(growable: false);
    final scopedIdeaIds = ideas.map((doc) => doc.id).toSet();
    final scores = results[3]
        .where((doc) => scopedIdeaIds.contains(((doc.data()['ideaId'] as String?) ?? '').trim()))
        .toList(growable: false);
    final problems = results[4].where((doc) => _matchesDept(doc.data(), dept)).toList(growable: false);
    final payments = results[5].where((doc) => _matchesDept(doc.data(), dept)).toList(growable: false);

    int roleCount(String role, {UserStatus? status}) {
      return users.where((doc) {
        final data = doc.data();
        final userRole = ((data['role'] as String?) ?? '').trim().toUpperCase();
        final userStatus = UserStatus.fromRaw((data['status'] as String?) ?? '');
        return userRole == role && (status == null || userStatus == status);
      }).length;
    }

    final int activeUsers = users
        .where((doc) => UserStatus.fromRaw((doc.data()['status'] as String?) ?? '') == UserStatus.active)
        .length;
    final int pendingApprovals = users
        .where((doc) => UserStatus.fromRaw((doc.data()['status'] as String?) ?? '') == UserStatus.pendingApproval)
        .length;
    final int pendingCoordinatorJudge = users.where((doc) {
      final data = doc.data();
      final role = ((data['role'] as String?) ?? '').trim().toUpperCase();
      final status = UserStatus.fromRaw((data['status'] as String?) ?? '');
      return (role == 'COO' || role == 'JUD') && status == UserStatus.pendingApproval;
    }).length;

    final List<IdeaStatus> ideaStatuses = ideas.map((doc) => IdeaStatus.fromRaw((doc.data()['status'] as String?) ?? '')).toList(growable: false);
    final int pendingSubmissionIdeas = ideaStatuses.where((s) => s == IdeaStatus.pendingSubmission).length;
    final int underReviewIdeas = ideaStatuses.where((s) => s == IdeaStatus.underReview).length;
    final int submittedIdeas = ideaStatuses.where((s) => s == IdeaStatus.submitted || s == IdeaStatus.underReview).length;
    final int evaluatedOnlyIdeas = ideaStatuses.where((s) => s == IdeaStatus.evaluated).length;
    final int evaluatedIdeas = ideaStatuses.where((s) => s == IdeaStatus.evaluated || s == IdeaStatus.approved).length;
    final int approvedIdeas = ideaStatuses.where((s) => s == IdeaStatus.approved).length;
    final int rejectedIdeas = ideaStatuses.where((s) => s == IdeaStatus.rejected).length;

    final List<PaymentRecordStatus> paymentStatuses = payments.map((doc) => PaymentRecordStatus.fromRaw((doc.data()['status'] as String?) ?? '')).toList(growable: false);
    final int pendingPayments = paymentStatuses.where((s) => s == PaymentRecordStatus.pending).length;
    final int verifiedPayments = paymentStatuses.where((s) => s == PaymentRecordStatus.verified).length;

    final analytics = DepartmentDashboardAnalytics(
      totalActiveUsers: activeUsers,
      pendingApprovals: pendingApprovals,
      activeProblems: problems.where((doc) => (doc.data()['isActive'] as bool?) ?? true).length,
      ideasSubmitted: ideas.length,
      facultyCount: roleCount('FAC', status: UserStatus.active),
      studentCount: roleCount('STU', status: UserStatus.active),
      coordinatorCount: roleCount('COO', status: UserStatus.active),
      judgeCount: roleCount('JUD', status: UserStatus.active),
      pendingCoordinatorJudgeCount: pendingCoordinatorJudge,
      pendingPayments: pendingPayments,
      pendingSubmissionIdeas: pendingSubmissionIdeas,
      underReviewIdeas: underReviewIdeas,
      submittedIdeas: submittedIdeas,
      evaluatedOnlyIdeas: evaluatedOnlyIdeas,
      evaluatedIdeas: evaluatedIdeas,
      approvedIdeas: approvedIdeas,
      rejectedIdeas: rejectedIdeas,
      trendsByTimeframe: <DepartmentAnalyticsTimeframe, List<DepartmentTrendPoint>>{
        for (final DepartmentAnalyticsTimeframe timeframe in DepartmentAnalyticsTimeframe.values)
          timeframe: _buildTrend(users, teams, ideas, scores, timeframe),
      },
      usersByRole: _roleDistribution(users),
      departmentProblems: _departmentProblems(problems, ideas),
      departmentIdeas: _departmentIdeas(ideas),
      alerts: _buildAlerts(
        pendingApprovals: pendingApprovals,
        pendingCoordinatorJudge: pendingCoordinatorJudge,
        pendingPayments: pendingPayments,
        ideas: ideas,
      ),
      recentActivity: _buildRecentActivity(users, problems, ideas, scores, payments),
      paymentVerificationRate: payments.isEmpty ? 0 : verifiedPayments / payments.length,
      evaluationCompletionRate: ideas.isEmpty ? 0 : evaluatedIdeas / ideas.length,
    );

    _cache[cacheKey] = analytics;
    _cacheAt[cacheKey] = DateTime.now();
    return analytics;
  }

  static bool isWithinTimeframe(DateTime when, DepartmentAnalyticsTimeframe timeframe) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    switch (timeframe) {
      case DepartmentAnalyticsTimeframe.currentWeek:
        final DateTime start = today.subtract(Duration(days: today.weekday - 1));
        return !when.isBefore(start) && when.isBefore(start.add(const Duration(days: 7)));
      case DepartmentAnalyticsTimeframe.lastWeek:
        final DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final DateTime start = currentWeekStart.subtract(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(currentWeekStart);
      case DepartmentAnalyticsTimeframe.lastMonth:
        return !when.isBefore(today.subtract(const Duration(days: 30)));
      case DepartmentAnalyticsTimeframe.lastSixMonths:
        return !when.isBefore(DateTime(today.year, today.month - 5, 1));
      case DepartmentAnalyticsTimeframe.all:
        return true;
    }
  }

  static Future<_FirestoreDocs> _fetchOrgCollection(String collection, String orgId) async {
    final snap = await FirebaseFirestore.instance.collection(collection).where('orgId', isEqualTo: orgId).get();
    return snap.docs;
  }

  static bool _matchesDept(Map<String, dynamic> data, String departmentCode) {
    final code = DepartmentModel.resolveCode((data['departmentCode'] as String?) ?? '');
    return code == departmentCode;
  }

  static List<DepartmentTrendPoint> _buildTrend(
    _FirestoreDocs users,
    _FirestoreDocs teams,
    _FirestoreDocs ideas,
    _FirestoreDocs scores,
    DepartmentAnalyticsTimeframe timeframe,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late final DateTime start;
    late final DateTime end;
    late final int bucketCount;
    late final Duration bucketSize;
    switch (timeframe) {
      case DepartmentAnalyticsTimeframe.currentWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case DepartmentAnalyticsTimeframe.lastWeek:
        end = today.subtract(Duration(days: today.weekday - 1));
        start = end.subtract(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case DepartmentAnalyticsTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
        break;
      case DepartmentAnalyticsTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
        break;
      case DepartmentAnalyticsTimeframe.all:
        final dates = <DateTime?>[
          ...users.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...teams.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...ideas.map((doc) => _dateFrom(doc.data()['createdAt'])),
          ...scores.map((doc) => _dateFrom(doc.data()['createdAt'])),
        ].whereType<DateTime>().toList(growable: false);
        final sortedDates = dates.toList(growable: false)..sort();
        start = sortedDates.isEmpty ? today.subtract(const Duration(days: 180)) : DateTime(sortedDates.first.year, sortedDates.first.month, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final int days = end.difference(start).inDays.clamp(1, 3650).toInt();
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365).toInt());
        break;
    }

    final buckets = List<DateTime>.generate(bucketCount, (int i) => start.add(Duration(days: bucketSize.inDays * i)));
    int countInBucket(_FirestoreDocs docs, int i) {
      final from = buckets[i];
      final to = i == buckets.length - 1 ? end : buckets[i + 1];
      return docs.where((doc) {
        final created = _dateFrom(doc.data()['createdAt']);
        return created != null && !created.isBefore(from) && created.isBefore(to);
      }).length;
    }

    return List<DepartmentTrendPoint>.generate(buckets.length, (int i) {
      return DepartmentTrendPoint(
        label: _bucketLabel(buckets[i], timeframe),
        users: countInBucket(users, i),
        teams: countInBucket(teams, i),
        ideas: countInBucket(ideas, i),
        evaluations: countInBucket(scores, i),
      );
    });
  }

  static List<DepartmentDistributionSegment> _roleDistribution(_FirestoreDocs users) {
    final counts = <String, int>{'Faculty': 0, 'Students': 0, 'Coordinators': 0, 'Judges': 0, 'Pending': 0};
    for (final doc in users) {
      final data = doc.data();
      final status = UserStatus.fromRaw((data['status'] as String?) ?? '');
      if (status == UserStatus.pendingApproval) {
        counts['Pending'] = counts['Pending']! + 1;
        continue;
      }
      switch (((data['role'] as String?) ?? '').trim().toUpperCase()) {
        case 'FAC':
          counts['Faculty'] = counts['Faculty']! + 1;
          break;
        case 'STU':
          counts['Students'] = counts['Students']! + 1;
          break;
        case 'COO':
          counts['Coordinators'] = counts['Coordinators']! + 1;
          break;
        case 'JUD':
          counts['Judges'] = counts['Judges']! + 1;
          break;
      }
    }
    const colors = <Color>[Color(0xFF6A38FF), Color(0xFF0EA5E9), Color(0xFF16A34A), Color(0xFFEA580C), Color(0xFFF59E0B)];
    const icons = <IconData>[
      AppIcons.faculty,
      AppIcons.student,
      AppIcons.coordinator,
      AppIcons.judges,
      AppIcons.pendingUsers,
    ];
    var index = 0;
    return counts.entries
        .map(
          (MapEntry<String, int> e) {
            final int i = index++;
            return DepartmentDistributionSegment(
              label: e.key,
              count: e.value,
              color: colors[i % colors.length],
              icon: icons[i % icons.length],
            );
          },
        )
        .toList(growable: false);
  }

  static List<DepartmentProblemPreview> _departmentProblems(_FirestoreDocs problems, _FirestoreDocs ideas) {
    final Map<String, int> ideaCountsByProblem = <String, int>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in ideas) {
      final String problemId = ((doc.data()['problemId'] as String?) ?? '').trim();
      if (problemId.isEmpty) continue;
      ideaCountsByProblem[problemId] = (ideaCountsByProblem[problemId] ?? 0) + 1;
    }

    final List<DepartmentProblemPreview> list = problems
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          final String title = ((data['title'] as String?) ?? 'Untitled Problem').trim();
          return DepartmentProblemPreview(
            problemId: doc.id,
            title: title.isEmpty ? 'Untitled Problem' : title,
            ideaCount: ideaCountsByProblem[doc.id] ?? 0,
          );
        })
        .toList(growable: false);
    list.sort((DepartmentProblemPreview a, DepartmentProblemPreview b) {
      final int byIdeas = b.ideaCount.compareTo(a.ideaCount);
      if (byIdeas != 0) return byIdeas;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  static List<DepartmentIdeaPreview> _departmentIdeas(_FirestoreDocs ideas) {
    final List<({DepartmentIdeaPreview preview, DateTime? created})> rows =
        <({DepartmentIdeaPreview preview, DateTime? created})>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in ideas) {
      final Map<String, dynamic> data = doc.data();
      final String title = ((data['ideaTitle'] as String?) ?? '').trim();
      rows.add((
        preview: DepartmentIdeaPreview(
          ideaId: doc.id,
          title: title.isEmpty ? 'Untitled Idea' : title,
          status: IdeaStatus.fromRaw((data['status'] as String?) ?? ''),
        ),
        created: _dateFrom(data['createdAt']),
      ));
    }
    rows.sort((a, b) {
      final DateTime left = a.created ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime right = b.created ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return rows.map((row) => row.preview).toList(growable: false);
  }

  static List<DepartmentAlert> _buildAlerts({
    required int pendingApprovals,
    required int pendingCoordinatorJudge,
    required int pendingPayments,
    required _FirestoreDocs ideas,
  }) {
    final alerts = <DepartmentAlert>[];
    if (pendingApprovals > 0) {
      alerts.add(DepartmentAlert(title: 'Pending user approvals', message: '$pendingApprovals department users are waiting for approval.', severity: DepartmentAlertSeverity.warning));
    }
    if (pendingCoordinatorJudge > 0) {
      alerts.add(DepartmentAlert(title: 'Coordinator / judge approvals', message: '$pendingCoordinatorJudge coordinator or judge requests are pending.', severity: DepartmentAlertSeverity.warning));
    }
    if (pendingPayments > 0) {
      alerts.add(DepartmentAlert(title: 'Payment validation backlog', message: '$pendingPayments payments need verification.', severity: DepartmentAlertSeverity.critical));
    }
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final stalled = ideas.where((doc) {
      final status = IdeaStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      final created = _dateFrom(doc.data()['createdAt']);
      return created != null && created.isBefore(cutoff) && (status == IdeaStatus.submitted || status == IdeaStatus.underReview);
    }).length;
    if (stalled > 0) {
      alerts.add(DepartmentAlert(title: 'Stalled evaluations', message: '$stalled ideas have waited more than 7 days.', severity: DepartmentAlertSeverity.warning));
    }
    if (alerts.isEmpty) {
      alerts.add(const DepartmentAlert(title: 'Department health looks steady', message: 'No operational alert thresholds are currently crossed.', severity: DepartmentAlertSeverity.info));
    }
    return alerts;
  }

  static List<DepartmentActivityEvent> _buildRecentActivity(
    _FirestoreDocs users,
    _FirestoreDocs problems,
    _FirestoreDocs ideas,
    _FirestoreDocs scores,
    _FirestoreDocs payments,
  ) {
    final events = <DepartmentActivityEvent>[];
    for (final doc in users) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(DepartmentActivityEvent(title: 'User added', subtitle: '${(data['firstName'] as String?) ?? ''} ${(data['lastName'] as String?) ?? ''}'.trim(), when: when, icon: AppIcons.users, tint: const Color(0xFF6A38FF)));
    }
    for (final doc in problems) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(DepartmentActivityEvent(title: 'Problem created', subtitle: ((data['title'] as String?) ?? 'Problem').trim(), when: when, icon: AppIcons.problems, tint: const Color(0xFFEA580C)));
    }
    for (final doc in ideas) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(DepartmentActivityEvent(
        title: 'Idea submitted',
        subtitle: ((data['ideaTitle'] as String?) ?? '').trim().isNotEmpty
            ? ((data['ideaTitle'] as String?) ?? '').trim()
            : ((data['problemTitle'] as String?) ?? 'Idea').trim(),
        when: when,
        icon: AppIcons.ideas,
        tint: const Color(0xFF0EA5E9),
      ));
    }
    for (final doc in scores) {
      final data = doc.data();
      final when = _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(DepartmentActivityEvent(title: 'Evaluation completed', subtitle: 'Idea ${((data['ideaId'] as String?) ?? '').trim()}', when: when, icon: AppIcons.scoring, tint: const Color(0xFF16A34A)));
    }
    for (final doc in payments) {
      final data = doc.data();
      if (PaymentRecordStatus.fromRaw((data['status'] as String?) ?? '') != PaymentRecordStatus.verified) continue;
      final when = _dateFrom(data['verifiedAt']) ?? _dateFrom(data['createdAt']);
      if (when == null) continue;
      events.add(DepartmentActivityEvent(title: 'Payment verified', subtitle: ((data['problemNumber'] as String?) ?? 'Payment').trim(), when: when, icon: AppIcons.payments, tint: const Color(0xFF0891B2)));
    }
    events.sort((a, b) => b.when.compareTo(a.when));
    return events.take(80).toList(growable: false);
  }

  static String _bucketLabel(DateTime date, DepartmentAnalyticsTimeframe timeframe) {
    switch (timeframe) {
      case DepartmentAnalyticsTimeframe.currentWeek:
      case DepartmentAnalyticsTimeframe.lastWeek:
        const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case DepartmentAnalyticsTimeframe.lastMonth:
        return '${date.month}/${date.day}';
      case DepartmentAnalyticsTimeframe.lastSixMonths:
      case DepartmentAnalyticsTimeframe.all:
        const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
    }
  }

  static DateTime? _dateFrom(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
