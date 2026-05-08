import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
import '../../models/user_model.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../../utils/student_dashboard_service.dart';
import '../../utils/common_helpers.dart';
import '../../widgets/student_team_overview_card.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.student, user),
          );
        }
        return _StudentDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _StudentDashboardHome extends StatefulWidget {
  const _StudentDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_StudentDashboardHome> createState() => _StudentDashboardHomeState();
}

class _StudentDashboardHomeState extends State<_StudentDashboardHome> {
  late Future<StudentDashboardVm> _future;
  final StudentDashboardService _service = StudentDashboardService();
  int _activityLimit = 8;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentDashboardVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load student dashboard: ${snapshot.error}');
        }
        final vm = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(vm),
              const SizedBox(height: 16),
              _buildStatusAndDetailsRow(vm),
              const SizedBox(height: 16),
              StudentTeamOverviewCard(vm: vm),
              const SizedBox(height: 16),
              _buildRecentActivity(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(StudentDashboardVm vm) {
    const spacing = 16.0;
    final inProgressIdeas = vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas;
    return LayoutBuilder(
      builder: (_, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = (maxWidth / 260).floor().clamp(1, 4);
        final cardWidth = (maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: cardWidth,
              child: DashboardCountCard(
                value: '${vm.teamMemberCount}',
                label: 'Members • ${vm.team.teamName.isEmpty ? 'No Team' : vm.team.teamName}',
                icon: AppIcons.teams,
                iconBgColor: const Color(0xFFEAF2FF),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardIconMetricCard(
                metrics: <DashboardIconMetric>[
                  DashboardIconMetric(
                    icon: AppIcons.statusSubmitted,
                    tooltip: 'In Progress (Pending + Submitted + Under Review)',
                    count: '$inProgressIdeas',
                    color: StatusStyles.submitted,
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusApproved,
                    tooltip: 'Approved',
                    count: '${vm.approvedIdeas}',
                    color: StatusStyles.approved,
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusRejected,
                    tooltip: 'Rejected',
                    count: '${vm.rejectedIdeas}',
                    color: StatusStyles.rejected,
                  ),
                ],
                label: 'Ideas',
                icon: AppIcons.ideas,
                iconBgColor: const Color(0xFFF2EDFF),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardCountCard(
                value: vm.avgScore?.toStringAsFixed(1) ?? '-',
                secondaryValue: vm.highestScore?.toStringAsFixed(1) ?? '-',
                label: 'Avg / Highest Score',
                icon: AppIcons.scoring,
                iconBgColor: const Color(0xFFE8FAF1),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DashboardIconMetricCard(
                metrics: <DashboardIconMetric>[
                  DashboardIconMetric(
                    icon: AppIcons.statusSubmitted,
                    tooltip: 'Pending',
                    count: '${vm.pendingPayments}',
                    color: const Color(0xFFB56A11),
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusApproved,
                    tooltip: 'Verified',
                    count: '${vm.verifiedPayments}',
                    color: const Color(0xFF177C50),
                  ),
                  DashboardIconMetric(
                    icon: AppIcons.statusRejected,
                    tooltip: 'Rejected',
                    count: '${vm.rejectedPayments}',
                    color: const Color(0xFFB93838),
                  ),
                ],
                label: 'Payments',
                icon: AppIcons.payments,
                iconBgColor: const Color(0xFFFFF4E8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusAndDetailsRow(StudentDashboardVm vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 252,
            child: _buildStudentDetails(vm),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 252,
            child: ChartCard(
              title: 'Idea Status Distribution',
              child: SizedBox(
                height: 188,
                child: _StudentIdeaStatusDonut(vm: vm),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDetails(StudentDashboardVm vm) {
    return ChartCard(
      title: 'Student Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _detailRow(icon: AppIcons.student, label: 'Student', value: vm.studentName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Department', value: vm.department),
          const SizedBox(height: 8),
          _detailRow(
            icon: AppIcons.teams,
            label: 'Team',
            value: vm.team.teamName.isEmpty ? '-' : vm.team.teamName,
          ),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.faculty, label: 'Mentor', value: vm.mentorName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Dept Admin', value: vm.departmentAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'College Admin', value: vm.collegeAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'Organization', value: vm.organizationName),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(StudentDashboardVm vm) {
    final visible = vm.activities.take(_activityLimit).toList(growable: false);
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('No recent activity.')
          else
            ...visible.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Icon(a.icon, size: 18, color: const Color(0xFF4B5AA9)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a.text)),
                    Text(
                      _formatDate(a.at),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
                    ),
                  ],
                ),
              ),
            ),
          if (_activityLimit < vm.activities.length)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _activityLimit += 8),
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 22,
          child: Icon(icon, size: 16, color: const Color(0xFF57629A)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B556A), fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF4B556A))),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return formatDateTime(date);
  }

}

class _StudentIdeaStatusDonut extends StatelessWidget {
  const _StudentIdeaStatusDonut({required this.vm});

  final StudentDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    final total =
        (vm.pendingIdeas +
                vm.submittedIdeas +
                vm.reviewIdeas +
                vm.evaluatedIdeas +
                vm.approvedIdeas +
                vm.rejectedIdeas)
            .clamp(1, 1 << 20);
    return Row(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.78,
            child: CustomPaint(
              painter: _StudentDonutPainter(
                pendingPct: vm.pendingIdeas / total,
                submittedPct: vm.submittedIdeas / total,
                reviewPct: vm.reviewIdeas / total,
                evaluatedPct: vm.evaluatedIdeas / total,
                approvedPct: vm.approvedIdeas / total,
                rejectedPct: vm.rejectedIdeas / total,
              ),
              child: Center(
                child: Text(
                  '${vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas + vm.evaluatedIdeas + vm.approvedIdeas + vm.rejectedIdeas}',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LegendRow(color: StatusStyles.submitted, text: 'Pending ${vm.pendingIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.submittedChart, text: 'Submitted ${vm.submittedIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.underReview, text: 'Under Review ${vm.reviewIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.evaluated, text: 'Evaluated ${vm.evaluatedIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.approved, text: 'Approved ${vm.approvedIdeas}'),
              const SizedBox(height: 6),
              _LegendRow(color: StatusStyles.rejected, text: 'Rejected ${vm.rejectedIdeas}'),
            ],
          ),
        ),
      ],
    );
  }
}


class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StudentDonutPainter extends CustomPainter {
  _StudentDonutPainter({
    required this.pendingPct,
    required this.submittedPct,
    required this.reviewPct,
    required this.evaluatedPct,
    required this.approvedPct,
    required this.rejectedPct,
  });

  final double pendingPct;
  final double submittedPct;
  final double reviewPct;
  final double evaluatedPct;
  final double approvedPct;
  final double rejectedPct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.shortestSide * 0.31);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    double start = -1.57;

    void arc(double value, Color color) {
      if (value <= 0) return;
      final sweep = 6.28318530718 * value;
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    arc(pendingPct, StatusStyles.submitted);
    arc(submittedPct, StatusStyles.submittedChart);
    arc(reviewPct, StatusStyles.underReview);
    arc(evaluatedPct, StatusStyles.evaluated);
    arc(approvedPct, StatusStyles.approved);
    arc(rejectedPct, StatusStyles.rejected);
  }

  @override
  bool shouldRepaint(covariant _StudentDonutPainter oldDelegate) {
    return oldDelegate.pendingPct != pendingPct ||
        oldDelegate.submittedPct != submittedPct ||
        oldDelegate.reviewPct != reviewPct ||
        oldDelegate.evaluatedPct != evaluatedPct ||
        oldDelegate.approvedPct != approvedPct ||
        oldDelegate.rejectedPct != rejectedPct;
  }
}

