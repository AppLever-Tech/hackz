import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/dashboard/collegeadmin/services/college_dashboard_analytics.dart';
import 'package:hackz/features/dashboard/deptadmin/services/department_dashboard_service.dart';

void main() {
  test('department comparison respects timeframe on createdAt', () {
    final DateTime now = DateTime(2026, 6, 15);
    final snapshot = CollegeDashboardSnapshot(
      org: null,
      departments: <Map<String, dynamic>>[
        <String, dynamic>{'code': 'CSE', 'name': 'Computer Science'},
      ],
      problems: <Map<String, dynamic>>[
        <String, dynamic>{
          'departmentCode': 'CSE',
          'createdAt': Timestamp.fromDate(DateTime(2026, 6, 10)),
        },
        <String, dynamic>{
          'departmentCode': 'CSE',
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        },
      ],
      ideas: <Map<String, dynamic>>[
        <String, dynamic>{
          'teamDepartmentCode': 'CSE',
          'createdAt': Timestamp.fromDate(DateTime(2026, 6, 12)),
        },
      ],
    );

    final CollegeDepartmentComparison recent =
        snapshot.departmentComparison(DepartmentAnalyticsTimeframe.all);
    expect(recent.ideas, <int>[1]);
    expect(recent.problems, <int>[2]);
  });

  test('role metrics aggregate department rosters', () {
    final snapshot = CollegeDashboardSnapshot(
      org: null,
      departments: <Map<String, dynamic>>[
        <String, dynamic>{
          'adminUserId': 'a1',
          'coordinatorCount': 2,
          'judgeCount': 1,
          'teamMemberCount': 10,
        },
        <String, dynamic>{
          'coordinatorCount': 1,
          'judgeCount': 0,
          'teamMemberCount': 5,
        },
      ],
      problems: const <Map<String, dynamic>>[],
      ideas: const <Map<String, dynamic>>[
        <String, dynamic>{'id': '1'},
        <String, dynamic>{'id': '2'},
      ],
    );

    final CollegeRoleMetrics metrics = snapshot.roleMetrics;
    expect(metrics.departments, 2);
    expect(metrics.departmentAdmins, 1);
    expect(metrics.coordinators, 3);
    expect(metrics.judges, 1);
    expect(metrics.teamMembers, 15);
    expect(metrics.ideasSubmitted, 2);
  });
}
