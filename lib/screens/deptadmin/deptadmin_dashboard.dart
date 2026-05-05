import 'package:flutter/material.dart';

import '../../models/enums/user_status.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../common/dashboard_page_template.dart';
import '../common/dashboard_components.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'judges_panel.dart';
import 'manage_users_screen.dart';
import 'pending_users_screen.dart';
import 'payments_screen.dart';

String _deptRoleLabel(String role) {
  switch (role.trim()) {
    case 'FAC':
      return 'Faculty';
    case 'COO':
      return 'Coordinator';
    case 'STU':
      return 'Student';
    default:
      return role;
  }
}

class DeptAdminDashboard extends StatelessWidget {
  const DeptAdminDashboard({super.key, required this.user});

  final UserModel user;

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final stats = await FirestoreUtils.getDepartmentStats(
      orgId: user.orgId,
      department: user.departmentCode,
    );
    final people = await FirestoreUtils.getDepartmentUsers(
      orgId: user.orgId,
      department: user.departmentCode,
      roleCodes: const <String>['FAC', 'STU'],
      limit: 10,
    );
    return <String, dynamic>{
      'stats': stats,
      'people': people,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.departmentAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: DepartmentAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ManageUsersScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 4) {
          return JudgesPanelScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 5) {
          return PendingUsersScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
          );
        }
        if (selectedMenuIndex == 6) {
          return PaymentsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 7) {
          return const SectionContainer(child: Text('Settings module placeholder'));
        }

        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey<int>(refreshToken),
          future: _loadDashboardData(),
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Unable to load department dashboard: ${snapshot.error}');
            }
            final data = snapshot.data ?? <String, dynamic>{};
            final stats = data['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
            final users = data['people'] as List<UserModel>? ?? <UserModel>[];
            final totalStudents = stats['totalStudents'] as int? ?? 0;
            final totalFaculty = stats['totalFaculty'] as int? ?? 0;
            final totalIdeas = stats['totalIdeas'] as int? ?? 0;
            final activeIdeas = stats['activeIdeas'] as int? ?? 0;
            final totalJudges = stats['totalJudges'] as int? ?? 0;
            final submittedIdeas = stats['submittedIdeas'] as int? ?? 0;
            final underReviewIdeas = stats['underReviewIdeas'] as int? ?? 0;
            final evaluatedIdeas = stats['evaluatedIdeas'] as int? ?? 0;
            final totalStatusIdeas = (submittedIdeas + underReviewIdeas + evaluatedIdeas).clamp(1, 1 << 20);
            final distribution = <_StatusSlice>[
              _StatusSlice('Submitted', submittedIdeas, const Color(0xFF6A38FF)),
              _StatusSlice('Under Review', underReviewIdeas, const Color(0xFFFFA726)),
              _StatusSlice('Evaluated', evaluatedIdeas, const Color(0xFF26A69A)),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SummaryCard(
                        value: '$totalStudents',
                        label: 'Total Students',
                        icon: Icons.school_outlined,
                        iconBgColor: const Color(0xFFEAF2FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        value: '$totalFaculty',
                        label: 'Total Faculty',
                        icon: Icons.person_outline,
                        iconBgColor: const Color(0xFFE9FAF0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        value: '$totalIdeas',
                        label: 'Total Ideas',
                        icon: Icons.lightbulb_outline,
                        iconBgColor: const Color(0xFFF2EDFF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        value: '$activeIdeas',
                        label: 'Active Ideas',
                        icon: Icons.autorenew_rounded,
                        iconBgColor: const Color(0xFFFFF2E8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        value: '$totalJudges',
                        label: 'Total Judges',
                        icon: Icons.gavel_outlined,
                        iconBgColor: const Color(0xFFE8F1FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: SectionContainer(
                        child: const SizedBox(
                          height: 220,
                          child: _DeptIdeaLinePlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SectionContainer(
                        child: SizedBox(
                          height: 220,
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 150,
                                        height: 150,
                                        child: CircularProgressIndicator(
                                          value: totalStatusIdeas == 0
                                              ? 0
                                              : (evaluatedIdeas / totalStatusIdeas),
                                          strokeWidth: 14,
                                          color: const Color(0xFF26A69A),
                                          backgroundColor: const Color(0xFFE8ECF8),
                                        ),
                                      ),
                                      Text(
                                        '$totalIdeas Ideas',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...distribution.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(s.label)),
                                      Text('${s.value}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'Faculty & Students Overview',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton(onPressed: () {}, child: const Text('View All')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (users.isEmpty)
                        const Text('No faculty/students found.')
                      else
                        ...users.map(
                          (u) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(child: Text('${u.firstName} ${u.lastName}'.trim())),
                                SizedBox(
                                  width: 100,
                                  child: Text(_deptRoleLabel(u.role)),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    u.status == UserStatus.active ? 'Active' : u.status.value,
                                    style: TextStyle(
                                      color: u.status == UserStatus.active ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatusSlice {
  const _StatusSlice(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _DeptIdeaLinePlaceholder extends StatelessWidget {
  const _DeptIdeaLinePlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DeptIdeaLinePainter(),
      child: Container(),
    );
  }
}

class _DeptIdeaLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = const Color(0xFF6A38FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.2, size.height * 0.73)
      ..lineTo(size.width * 0.4, size.height * 0.62)
      ..lineTo(size.width * 0.6, size.height * 0.56)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.32);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
