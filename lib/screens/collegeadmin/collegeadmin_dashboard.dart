import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../core/theme/app_icons.dart';
import '../../features/organization/models/organization_model.dart';
import '../../features/user/models/enums/user_role.dart';
import '../../features/user/models/user_model.dart';
import '../../features/org_settings/collegeadmin/org_settings_dashboard.dart';
import '../../utils/firestore_utils.dart';
import '../../features/idea/services/idea_role_config.dart';
import '../../features/problems/services/problem_role_config.dart';
import '../common/dashboard_page_template.dart';
import '../../features/leaderboard/screens/leaderboard_showcase_screen.dart';
import '../common/dashboard_components.dart';
import '../../features/idea/screens/ideas_list_screen.dart';
import '../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../core/responsive/adaptive_dashboard_panel.dart';
import '../../core/responsive/responsive_columns.dart';
import '../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../core/responsive/responsive_metric_grid.dart';
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
      FirestoreUtils.getCollegeIdeaActivityTrend(user.orgId),
      FirestoreUtils.getIdeaCountsByDepartmentCode(user.orgId),
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
      'ideaActivity': results[4] as List<Map<String, dynamic>>,
      'ideasByDept': results[5] as Map<String, int>,
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
          return ProblemStatementsTableScreen(
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
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 5) {
          return OrgSettingsDashboard(
            key: ValueKey<int>(refreshToken),
            user: user,
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
            final ideaActivity =
                data['ideaActivity'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];
            final org = data['org'] as OrganizationModel?;

            final int totalDepartments = stats['totalDepartments'] as int? ?? 0;
            final int totalUsers = stats['totalUsers'] as int? ?? 0;
            final int activeUsers = stats['activeUsers'] as int? ?? 0;
            final int pendingUsers = stats['pendingUsers'] as int? ?? 0;
            final int totalProblems = stats['totalProblems'] as int? ?? 0;
            final int totalIdeas = stats['totalIdeas'] as int? ?? 0;
            final double activePct = totalUsers == 0 ? 0 : (activeUsers / totalUsers);
            final int activationPercent = (activePct * 100).round();
            final ideasByDept = data['ideasByDept'] as Map<String, int>? ?? <String, int>{};
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

            final gap = ResponsiveHelper.dashboardSectionGap(context);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                ResponsiveMetricGrid(
                  chips: <DashboardMetricChipData>[
                    DashboardMetricChipData.single(
                      label: 'Total Departments',
                      value: '$totalDepartments',
                      color: const Color(0xFF4A67FF),
                      icon: AppIcons.departments,
                    ),
                    DashboardMetricChipData.single(
                      label: 'Total Users',
                      value: '$totalUsers',
                      color: const Color(0xFFEA580C),
                      icon: AppIcons.users,
                    ),
                    DashboardMetricChipData.single(
                      label: 'Problem Statements',
                      value: '$totalProblems',
                      color: const Color(0xFF059669),
                      icon: AppIcons.problems,
                    ),
                    DashboardMetricChipData.single(
                      label: 'Ideas (College)',
                      value: '$totalIdeas',
                      color: const Color(0xFF7C3AED),
                      icon: AppIcons.ideas,
                    ),
                  ],
                ),
                SizedBox(height: gap),
                ResponsivePair(
                  spacing: gap,
                  secondFlex: 2,
                  first: ChartCard(
                    title: 'College Details',
                    icon: AppIcons.organizations,
                    child: ResponsiveChartBox(
                      desktopHeight: 200,
                      child: SingleChildScrollView(
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
                  second: ChartCard(
                    title: 'Department-wise Problems vs Ideas',
                    icon: AppIcons.departments,
                    child: ResponsiveChartBox(
                      desktopHeight: 200,
                      child: _DepartmentTrendChart(
                        labels: plotKeys,
                        ideas: ideaSeries,
                        problems: problemSeries,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                ResponsivePair(
                  spacing: gap,
                  secondFlex: 2,
                  first: ChartCard(
                    title: 'User Activation',
                    icon: AppIcons.users,
                    child: ResponsiveChartBox(
                      desktopHeight: 220,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              height: ResponsiveHelper.isMobile(context) ? 120 : 150,
                              width: ResponsiveHelper.isMobile(context) ? 120 : 150,
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
                  second: ChartCard(
                    title: 'Idea Activity',
                    icon: AppIcons.ideas,
                    child: ResponsiveChartBox(
                      desktopHeight: 220,
                      child: _IdeaActivityChart(points: ideaActivity),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const DashboardCardTitle(
                        title: 'Department Overview',
                        icon: AppIcons.departments,
                      ),
                      const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
                      if (departments.isEmpty)
                        const Text('No departments configured for this college.')
                      else
                        ...departments.map(
                          (dept) => _DepartmentOverviewTile(dept: dept),
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
      padding: const EdgeInsets.only(bottom: 6),
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

class _DepartmentOverviewTile extends StatelessWidget {
  const _DepartmentOverviewTile({required this.dept});

  final Map<String, dynamic> dept;

  @override
  Widget build(BuildContext context) {
    final int faculty = (dept['facultyCount'] as int?) ?? 0;
    final int students = (dept['studentCount'] as int?) ?? 0;
    final String admin = ((dept['departmentAdmin'] as String?) ?? '-').trim();
    final bool hasAdmin = admin.isNotEmpty && admin != '-';
    final String name = (dept['name'] as String?) ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout(
              name: name,
              admin: admin,
              hasAdmin: hasAdmin,
              faculty: faculty,
              students: students,
            )
          : _buildDesktopLayout(
              name: name,
              admin: admin,
              hasAdmin: hasAdmin,
              faculty: faculty,
              students: students,
            ),
    );
  }

  Widget _buildDesktopLayout({
    required String name,
    required String admin,
    required bool hasAdmin,
    required int faculty,
    required int students,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              _DepartmentIconBadge(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (hasAdmin)
                  _DepartmentMetricPill(
                    icon: AppIcons.adminProfile,
                    label: admin,
                    tooltip: 'Department admin',
                  ),
                _DepartmentMetricPill(
                  icon: AppIcons.faculty,
                  label: '$faculty',
                  tooltip: 'Faculty',
                ),
                _DepartmentMetricPill(
                  icon: AppIcons.student,
                  label: '$students',
                  tooltip: 'Students',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required String name,
    required String admin,
    required bool hasAdmin,
    required int faculty,
    required int students,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _DepartmentIconBadge(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.25,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (hasAdmin)
              Expanded(
                child: _DepartmentMetricPill(
                  icon: AppIcons.adminProfile,
                  label: admin,
                  tooltip: 'Department admin',
                  shrinkLabel: true,
                ),
              ),
            if (hasAdmin) const SizedBox(width: 8),
            if (!hasAdmin) const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DepartmentMetricCount(
                  icon: AppIcons.faculty,
                  count: faculty,
                  tooltip: 'Faculty',
                ),
                const SizedBox(width: 14),
                _DepartmentMetricCount(
                  icon: AppIcons.student,
                  count: students,
                  tooltip: 'Students',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DepartmentIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Tooltip(
          message: 'Department',
          child: Icon(AppIcons.departments, size: 18, color: Color(0xFF4F46E5)),
        ),
      ),
    );
  }
}

class _DepartmentMetricCount extends StatelessWidget {
  const _DepartmentMetricCount({
    required this.icon,
    required this.count,
    required this.tooltip,
  });

  final IconData icon;
  final int count;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF57629A)),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentMetricPill extends StatelessWidget {
  const _DepartmentMetricPill({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.shrinkLabel = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool shrinkLabel;

  @override
  Widget build(BuildContext context) {
    final Widget labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: shrinkLabel ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: const Color(0xFF57629A)),
            const SizedBox(width: 5),
            if (shrinkLabel)
              Expanded(child: labelWidget)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: labelWidget,
              ),
          ],
        ),
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
                  painter: _DepartmentTrendPainter(labels: labels, ideas: ideas, problems: problems),
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
            'Departments',
            style: TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
          ),
        ),
      ],
    );
  }
}

class _IdeaActivityChart extends StatelessWidget {
  const _IdeaActivityChart({required this.points});

  final List<Map<String, dynamic>> points;

  @override
  Widget build(BuildContext context) {
    final labels = points.map((p) => (p['label'] as String?) ?? '').toList(growable: false);
    final counts = points.map((p) => (p['count'] as int?) ?? 0).toList(growable: false);
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
                  painter: _IdeaLinePainter(labels: labels, counts: counts),
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
  const _IdeaLinePainter({
    required this.labels,
    required this.counts,
  });

  final List<String> labels;
  final List<int> counts;

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

    final maxValue = counts.fold<int>(1, (int max, int value) => value > max ? value : max);
    final yTicks = List<int>.generate(5, (int i) => (maxValue * i / 4).round());
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

    if (counts.isEmpty) return;

    final line = Paint()
      ..color = const Color(0xFF6A38FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = const Color(0xFF6A38FF);
    final path = Path();
    for (int i = 0; i < counts.length; i++) {
      final t = counts.length == 1 ? 0.5 : i / (counts.length - 1);
      final x = chartRect.left + chartRect.width * t;
      final y = chartRect.bottom - ((counts[i] / maxValue) * chartRect.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.2, dot);
    }
    canvas.drawPath(path, line);

    for (int i = 0; i < labels.length; i++) {
      final t = labels.length == 1 ? 0.5 : i / (labels.length - 1);
      final x = chartRect.left + (chartRect.width * t);
      final xLabel = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      xLabel.paint(
        canvas,
        Offset(x - (xLabel.width / 2), chartRect.bottom + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IdeaLinePainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.counts != counts;
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
    const leftPad = 30.0;
    const rightPad = 8.0;
    const topPad = 10.0;
    const bottomPad = 28.0;
    final rect = Rect.fromLTWH(leftPad, topPad, size.width - leftPad - rightPad, size.height - topPad - bottomPad);
    final count = labels.isEmpty ? 1 : labels.length;
    final maxValueInt = <int>[...ideas, ...problems].fold<int>(1, (a, b) => a > b ? a : b);
    final maxValue = maxValueInt.toDouble();
    final labelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);

    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = rect.top + (rect.height * i / 3);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      final tickValue = (maxValueInt * (3 - i) / 3).round();
      final yLabel = TextPainter(
        text: TextSpan(text: '$tickValue', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      yLabel.paint(canvas, Offset(2, y - (yLabel.height / 2)));
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
