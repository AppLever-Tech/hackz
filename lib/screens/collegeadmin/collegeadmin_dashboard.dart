import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../constants/app_icons.dart';
import '../../models/organization_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../common/dashboard_page_template.dart';
import '../common/dashboard_components.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'manage_college_screen.dart';

class CollegeAdminDashboard extends StatelessWidget {
  const CollegeAdminDashboard({super.key, required this.user});

  final UserModel user;

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.getCollegeStats(user.orgId),
      FirestoreUtils.getDepartmentsByCollege(user.orgId),
      FirestoreUtils.getProblemStatementsByCollege(user.orgId),
      FirestoreUtils.getOrganizations(),
    ]);
    final organizations = results[3] as List<OrganizationModel>;
    final org = organizations.where((o) => o.id == user.orgId).cast<OrganizationModel?>().firstWhere(
          (o) => o != null,
          orElse: () => null,
        );
    return <String, dynamic>{
      'stats': results[0] as Map<String, dynamic>,
      'departments': results[1] as List<Map<String, dynamic>>,
      'problems': results[2] as List<Map<String, dynamic>>,
      'org': org,
    };
  }

  Uri? _parseWebsiteUri(String website) {
    final normalized = website.trim();
    if (normalized.isEmpty || normalized == '-') return null;
    final withScheme = normalized.startsWith(RegExp(r'https?://'))
        ? normalized
        : 'https://$normalized';
    return Uri.tryParse(withScheme);
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.collegeAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: CollegeAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ManageCollegeScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.collegeAdmin, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.collegeAdmin, user),
          );
        }
        if (selectedMenuIndex == 4) {
          return const SectionContainer(
            child: Text('Settings module placeholder'),
          );
        }
        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey<int>(refreshToken),
          future: _loadDashboardData(),
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Unable to load college dashboard: ${snapshot.error}');
            }

            final data = snapshot.data ?? <String, dynamic>{};
            final stats = data['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
            final departments =
                data['departments'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];
            final problems = data['problems'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];
            final org = data['org'] as OrganizationModel?;

            final int totalDepartments = stats['totalDepartments'] as int? ?? 0;
            final int totalUsers = stats['totalUsers'] as int? ?? 0;
            final int activeUsers = stats['activeUsers'] as int? ?? 0;
            final int pendingUsers = stats['pendingUsers'] as int? ?? 0;
            final int totalProblems = stats['totalProblems'] as int? ?? 0;
            final int totalIdeas = stats['totalIdeas'] as int? ?? 0;
            final double activePct = totalUsers == 0 ? 0 : (activeUsers / totalUsers);
            final int activationPercent = (activePct * 100).round();
            final ideasByDept = <String, int>{};
            for (final d in departments) {
              final key = ((d['code'] as String?) ?? (d['name'] as String?) ?? '').trim();
              if (key.isEmpty) continue;
              ideasByDept[key] = (d['totalIdeas'] as int?) ?? 0;
            }
            final problemsByDept = <String, int>{};
            for (final p in problems) {
              final key = ((p['departmentCode'] as String?) ?? (p['department'] as String?) ?? '').trim();
              if (key.isEmpty) continue;
              problemsByDept[key] = (problemsByDept[key] ?? 0) + 1;
            }
            final deptKeys = <String>{...ideasByDept.keys, ...problemsByDept.keys}.toList(growable: false)..sort();
            final plotKeys = deptKeys.take(6).toList(growable: false);
            final ideaSeries = plotKeys.map((k) => ideasByDept[k] ?? 0).toList(growable: false);
            final problemSeries = plotKeys.map((k) => problemsByDept[k] ?? 0).toList(growable: false);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalDepartments',
                        label: 'Total Departments',
                        icon: AppIcons.departments,
                        iconBgColor: const Color(0xFFEAF2FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalUsers',
                        label: 'Total Users',
                        icon: AppIcons.users,
                        iconBgColor: const Color(0xFFFFF4E8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalProblems',
                        label: 'Problem Statements',
                        icon: AppIcons.problems,
                        iconBgColor: const Color(0xFFE8FAF1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalIdeas',
                        label: 'Ideas (College)',
                        icon: AppIcons.ideas,
                        iconBgColor: const Color(0xFFF2EDFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ChartCard(
                        title: 'College Details',
                        child: SizedBox(
                          height: 190,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _CollegeDetailItem(icon: AppIcons.organizations, label: 'Name', value: (org?.name ?? user.orgId)),
                              _CollegeDetailItem(icon: AppIcons.orgType, label: 'Type', value: org?.type.displayName ?? 'College'),
                              _CollegeDetailItem(
                                icon: AppIcons.address,
                                label: 'Address',
                                value: org?.address.isNotEmpty == true ? org!.address : '-',
                                wrapValue: true,
                              ),
                              _CollegeDetailItem(
                                icon: AppIcons.website,
                                label: 'Website',
                                value: org?.website.isNotEmpty == true ? org!.website : '-',
                                trailing: Builder(
                                  builder: (BuildContext context) {
                                    final uri = _parseWebsiteUri(org?.website ?? '');
                                    if (uri == null) return const SizedBox.shrink();
                                    return Link(
                                      uri: uri,
                                      target: LinkTarget.blank,
                                      builder: (BuildContext context, Future<void> Function()? followLink) {
                                        return IconButton(
                                          onPressed: followLink,
                                          icon: const Icon(
                                            AppIcons.openInNew,
                                            size: 18,
                                            color: Color(0xFF5A5F87),
                                          ),
                                          tooltip: 'Open website',
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          padding: EdgeInsets.zero,
                                          splashRadius: 18,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              _CollegeDetailItem(icon: AppIcons.phone, label: 'Contact', value: org?.contact.isNotEmpty == true ? org!.contact : '-'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ChartCard(
                        title: 'Department-wise Problems vs Ideas',
                        child: SizedBox(
                          height: 200,
                          child: _DepartmentTrendChart(
                            labels: plotKeys,
                            ideas: ideaSeries,
                            problems: problemSeries,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ChartCard(
                        title: 'User Activation',
                        child: SizedBox(
                          height: 220,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: CircularProgressIndicator(
                                    value: activePct,
                                    strokeWidth: 14,
                                    color: const Color(0xFF6A38FF),
                                    backgroundColor: const Color(0xFFE8ECF8),
                                  ),
                                ),
                                Text(
                                  '$activationPercent% Active\n$pendingUsers Pending',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ChartCard(
                        title: 'Idea Activity',
                        child: const SizedBox(
                          height: 220,
                          child: _IdeaActivityChart(),
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
                      const Text(
                        'Department Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (departments.isEmpty)
                        const Text('No departments configured for this college.')
                      else
                        ...departments.map(
                          (dept) {
                            final ideas = (dept['totalIdeas'] as int?) ?? 0;
                            final users = (dept['totalUsers'] as int?) ?? 0;
                            final bool active = ideas > 0 || users > 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      (dept['name'] as String?) ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text((dept['departmentAdmin'] as String?) ?? '-'),
                                  ),
                                  SizedBox(width: 90, child: Text('Users: $users')),
                                  SizedBox(width: 90, child: Text('Ideas: $ideas')),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      active ? 'Active' : 'Low Activity',
                                      style: TextStyle(
                                        color: active ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {},
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CollegeDetailItem extends StatelessWidget {
  const _CollegeDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.wrapValue = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wrapValue;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: wrapValue ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 18,
            child: Icon(icon, size: 16, color: const Color(0xFF5A5F87)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A4F73),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: wrapValue ? 3 : 1,
              overflow: wrapValue ? TextOverflow.visible : TextOverflow.ellipsis,
              softWrap: wrapValue,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A4F73)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DepartmentTrendChart extends StatelessWidget {
  const _DepartmentTrendChart({
    required this.labels,
    required this.ideas,
    required this.problems,
  });

  final List<String> labels;
  final List<int> ideas;
  final List<int> problems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Row(
          children: <Widget>[
            _LegendDot(color: Color(0xFF6A38FF), label: 'Ideas'),
            SizedBox(width: 12),
            _LegendDot(color: Color(0xFFFF8C2B), label: 'Problems'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            painter: _DepartmentTrendPainter(labels: labels, ideas: ideas, problems: problems),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _IdeaActivityChart extends StatelessWidget {
  const _IdeaActivityChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(
          children: <Widget>[
            _LegendDot(color: Color(0xFF6A38FF), label: 'Ideas Submitted'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Count',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomPaint(
                  painter: _IdeaLinePainter(),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Align(
          alignment: Alignment.center,
          child: Text(
            'Dates',
            style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4A4F73)),
        ),
      ],
    );
  }
}

class _IdeaLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 30.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 20.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final labelStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 10,
    );

    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;

    const yTicks = <int>[0, 10, 20, 30, 40];
    for (int i = 0; i < yTicks.length; i++) {
      final t = i / (yTicks.length - 1);
      final y = chartRect.bottom - (chartRect.height * t);
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), grid);

      final yLabel = TextPainter(
        text: TextSpan(text: '${yTicks[i]}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      yLabel.paint(canvas, Offset(2, y - (yLabel.height / 2)));
    }

    final line = Paint()
      ..color = const Color(0xFF6A38FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(chartRect.left + chartRect.width * 0.0, chartRect.top + chartRect.height * 0.80)
      ..lineTo(chartRect.left + chartRect.width * 0.2, chartRect.top + chartRect.height * 0.68)
      ..lineTo(chartRect.left + chartRect.width * 0.4, chartRect.top + chartRect.height * 0.72)
      ..lineTo(chartRect.left + chartRect.width * 0.6, chartRect.top + chartRect.height * 0.50)
      ..lineTo(chartRect.left + chartRect.width * 0.8, chartRect.top + chartRect.height * 0.46)
      ..lineTo(chartRect.left + chartRect.width * 1.0, chartRect.top + chartRect.height * 0.30);
    canvas.drawPath(path, line);

    const xLabels = <String>['01 Apr', '05 Apr', '10 Apr', '15 Apr', '20 Apr', '25 Apr'];
    for (int i = 0; i < xLabels.length; i++) {
      final t = i / (xLabels.length - 1);
      final x = chartRect.left + (chartRect.width * t);
      final xLabel = TextPainter(
        text: TextSpan(text: xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      xLabel.paint(
        canvas,
        Offset(x - (xLabel.width / 2), chartRect.bottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DepartmentTrendPainter extends CustomPainter {
  _DepartmentTrendPainter({
    required this.labels,
    required this.ideas,
    required this.problems,
  });

  final List<String> labels;
  final List<int> ideas;
  final List<int> problems;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 12.0;
    const rightPad = 8.0;
    const topPad = 10.0;
    const bottomPad = 28.0;
    final rect = Rect.fromLTWH(leftPad, topPad, size.width - leftPad - rightPad, size.height - topPad - bottomPad);
    final count = labels.isEmpty ? 1 : labels.length;
    final maxValue = <int>[...ideas, ...problems].fold<int>(1, (a, b) => a > b ? a : b).toDouble();

    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = rect.top + (rect.height * i / 3);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }

    Offset pointAt(int i, int value) {
      final x = rect.left + (rect.width * (count == 1 ? 0.5 : i / (count - 1)));
      final y = rect.bottom - ((value / maxValue) * rect.height);
      return Offset(x, y);
    }

    final ideaPath = Path();
    final problemPath = Path();
    for (int i = 0; i < count; i++) {
      final p1 = pointAt(i, i < ideas.length ? ideas[i] : 0);
      final p2 = pointAt(i, i < problems.length ? problems[i] : 0);
      if (i == 0) {
        ideaPath.moveTo(p1.dx, p1.dy);
        problemPath.moveTo(p2.dx, p2.dy);
      } else {
        ideaPath.lineTo(p1.dx, p1.dy);
        problemPath.lineTo(p2.dx, p2.dy);
      }
    }

    canvas.drawPath(
      ideaPath,
      Paint()
        ..color = const Color(0xFF6A38FF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      problemPath,
      Paint()
        ..color = const Color(0xFFFF8C2B)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final labelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);
    for (int i = 0; i < count; i++) {
      final x = rect.left + (rect.width * (count == 1 ? 0.5 : i / (count - 1)));
      final txt = labels.isEmpty ? '-' : labels[i];
      final tp = TextPainter(
        text: TextSpan(text: txt, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 46);
      tp.paint(canvas, Offset(x - (tp.width / 2), rect.bottom + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _DepartmentTrendPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.ideas != ideas || oldDelegate.problems != problems;
}
