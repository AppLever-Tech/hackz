import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/idea/services/idea_department_helpers.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../deptadmin/services/department_dashboard_service.dart';

class CollegeRoleMetrics {
  const CollegeRoleMetrics({
    required this.departments,
    required this.departmentAdmins,
    required this.coordinators,
    required this.judges,
    required this.teamMembers,
    required this.ideasSubmitted,
  });

  final int departments;
  final int departmentAdmins;
  final int coordinators;
  final int judges;
  final int teamMembers;
  final int ideasSubmitted;
}

class CollegeTrendPoint {
  const CollegeTrendPoint({required this.label, required this.count});

  final String label;
  final int count;
}

class CollegeDepartmentComparison {
  const CollegeDepartmentComparison({
    required this.labels,
    required this.ideas,
    required this.problems,
  });

  final List<String> labels;
  final List<int> ideas;
  final List<int> problems;

  bool get isEmpty =>
      ideas.every((int v) => v == 0) && problems.every((int v) => v == 0);
}

class CollegeDashboardSnapshot {
  CollegeDashboardSnapshot({
    required this.org,
    required this.departments,
    required this.problems,
    required this.ideas,
  });

  final OrganizationModel? org;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> problems;
  final List<Map<String, dynamic>> ideas;

  CollegeRoleMetrics get roleMetrics {
    int coordinators = 0;
    int judges = 0;
    int teamMembers = 0;
    int departmentAdmins = 0;
    for (final Map<String, dynamic> dept in departments) {
      coordinators += (dept['coordinatorCount'] as int?) ?? 0;
      judges += (dept['judgeCount'] as int?) ?? 0;
      teamMembers += (dept['teamMemberCount'] as int?) ?? 0;
      final String adminId = (dept['adminUserId'] as String?)?.trim() ?? '';
      if (adminId.isNotEmpty) departmentAdmins++;
    }
    return CollegeRoleMetrics(
      departments: departments.length,
      departmentAdmins: departmentAdmins,
      coordinators: coordinators,
      judges: judges,
      teamMembers: teamMembers,
      ideasSubmitted: ideas.length,
    );
  }

  CollegeDepartmentComparison departmentComparison(DepartmentAnalyticsTimeframe timeframe) {
    final Map<String, String> codeToName = <String, String>{
      for (final Map<String, dynamic> d in departments)
        if (((d['code'] as String?) ?? '').trim().isNotEmpty)
          ((d['code'] as String?) ?? '').trim().toUpperCase(): (d['name'] as String?) ?? '',
    };

    final Map<String, int> ideaCounts = <String, int>{};
    final Map<String, int> problemCounts = <String, int>{};

    for (final Map<String, dynamic> idea in ideas) {
      final DateTime? when = _asDate(idea['createdAt']);
      if (when == null || !DepartmentDashboardService.isWithinTimeframe(when, timeframe)) continue;
      final String code = IdeaDepartmentHelpers.teamDeptFromMap(idea);
      if (code.isEmpty) continue;
      ideaCounts[code] = (ideaCounts[code] ?? 0) + 1;
    }
    for (final Map<String, dynamic> problem in problems) {
      final DateTime? when = _asDate(problem['createdAt']);
      if (when == null || !DepartmentDashboardService.isWithinTimeframe(when, timeframe)) continue;
      final String code = ((problem['departmentCode'] as String?) ?? (problem['department'] as String?) ?? '')
          .trim()
          .toUpperCase();
      if (code.isEmpty) continue;
      problemCounts[code] = (problemCounts[code] ?? 0) + 1;
    }

    final Set<String> keys = <String>{...ideaCounts.keys, ...problemCounts.keys};
    final List<String> sorted = keys.toList(growable: false)
      ..sort((String a, String b) {
        final int totalA = (ideaCounts[a] ?? 0) + (problemCounts[a] ?? 0);
        final int totalB = (ideaCounts[b] ?? 0) + (problemCounts[b] ?? 0);
        final int byTotal = totalB.compareTo(totalA);
        if (byTotal != 0) return byTotal;
        return a.compareTo(b);
      });

    final List<String> plotKeys = sorted.take(8).toList(growable: false);
    final List<String> labels = plotKeys
        .map((String code) {
          final String name = (codeToName[code] ?? '').trim();
          if (name.isNotEmpty) return name;
          return code;
        })
        .toList(growable: false);

    return CollegeDepartmentComparison(
      labels: labels,
      ideas: plotKeys.map((String k) => ideaCounts[k] ?? 0).toList(growable: false),
      problems: plotKeys.map((String k) => problemCounts[k] ?? 0).toList(growable: false),
    );
  }

  List<CollegeTrendPoint> ideaActivityTrend(DepartmentAnalyticsTimeframe timeframe) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
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
      case DepartmentAnalyticsTimeframe.lastWeek:
        end = today.subtract(Duration(days: today.weekday - 1));
        start = end.subtract(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
      case DepartmentAnalyticsTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
      case DepartmentAnalyticsTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
      case DepartmentAnalyticsTimeframe.all:
        final List<DateTime> dates = ideas
            .map((Map<String, dynamic> m) => _asDate(m['createdAt']))
            .whereType<DateTime>()
            .toList(growable: false)
          ..sort();
        start = dates.isEmpty
            ? today.subtract(const Duration(days: 180))
            : DateTime(dates.first.year, dates.first.month, dates.first.day);
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final int days = end.difference(start).inDays.clamp(1, 3650);
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365));
    }

    final List<DateTime> buckets =
        List<DateTime>.generate(bucketCount, (int i) => start.add(Duration(days: bucketSize.inDays * i)));

    final List<int> counts = List<int>.filled(bucketCount, 0);
    for (final Map<String, dynamic> idea in ideas) {
      final DateTime? created = _asDate(idea['createdAt']);
      if (created == null) continue;
      if (!DepartmentDashboardService.isWithinTimeframe(created, timeframe)) continue;

      for (int i = 0; i < buckets.length; i++) {
        final DateTime from = buckets[i];
        final DateTime to = i == buckets.length - 1 ? end : buckets[i + 1];
        if (!created.isBefore(from) && created.isBefore(to)) {
          counts[i]++;
          break;
        }
      }
    }

    return List<CollegeTrendPoint>.generate(
      buckets.length,
      (int i) => CollegeTrendPoint(
        label: _bucketLabel(buckets[i], timeframe),
        count: counts[i],
      ),
      growable: false,
    );
  }

  static DateTime? _asDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  static String _bucketLabel(DateTime date, DepartmentAnalyticsTimeframe timeframe) {
    switch (timeframe) {
      case DepartmentAnalyticsTimeframe.currentWeek:
      case DepartmentAnalyticsTimeframe.lastWeek:
        const List<String> days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case DepartmentAnalyticsTimeframe.lastMonth:
        return '${date.month}/${date.day}';
      case DepartmentAnalyticsTimeframe.lastSixMonths:
      case DepartmentAnalyticsTimeframe.all:
        const List<String> months = <String>[
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return months[date.month - 1];
    }
  }
}
