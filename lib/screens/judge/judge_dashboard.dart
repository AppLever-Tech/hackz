import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/idea_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/judge_dashboard_service.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/common/dashboard_card/dashboard_card_layout.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../widgets/responsive/responsive_multi_column.dart';
import 'judge_evaluation_workspace_screen.dart';

class JudgeDashboard extends StatelessWidget {
  const JudgeDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return JudgeEvaluationWorkspaceScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return _JudgeDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _JudgeDashboardHome extends StatefulWidget {
  const _JudgeDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_JudgeDashboardHome> createState() => _JudgeDashboardHomeState();
}

class _JudgeDashboardHomeState extends State<_JudgeDashboardHome> {
  static const double _kActivityIconSize = 18;
  final JudgeDashboardService _service = JudgeDashboardService();
  late Future<JudgeDashboardVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JudgeDashboardVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load judge dashboard: ${snapshot.error}');
        }
        final vm = snapshot.data!;
        final gap = ResponsiveHelper.dashboardSectionGap(context);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(vm),
              SizedBox(height: gap),
              _buildInsights(vm),
              SizedBox(height: gap),
              _buildJudgeInfoAndWorkload(vm),
              SizedBox(height: gap),
              _buildRecentActivity(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(JudgeDashboardVm vm) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Assigned Ideas',
          value: '${vm.assignedIdeas}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Evaluated Ideas',
          value: '${vm.evaluatedIdeas}',
          color: const Color(0xFF16A34A),
          icon: AppIcons.statusEvaluated,
        ),
        DashboardMetricChipData.single(
          label: 'Pending Reviews',
          value: '${vm.pendingReviews}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.statusUnderReview,
        ),
        DashboardMetricChipData.single(
          label: 'Average Score Given',
          value: vm.averageScoreGiven?.toStringAsFixed(1) ?? '-',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.scoring,
        ),
      ],
    );
  }

  Widget _buildInsights(JudgeDashboardVm vm) {
    return ResponsiveMultiColumn(
      spacing: ResponsiveHelper.dashboardSectionGap(context),
      children: <Widget>[
        _buildStatusDistributionChart(vm),
        _buildScoreDistributionChart(vm),
        _buildEvaluationTimelineChart(vm),
      ],
    );
  }

  Widget _buildStatusDistributionChart(JudgeDashboardVm vm) {
    return ChartCard(
      title: 'Evaluation Status Distribution',
      icon: AppIcons.statusEvaluated,
      child: ResponsiveChartBox(
        desktopHeight: 210,
        child: _JudgeStatusDonut(
          pending: vm.pendingDistributionCount,
          completed: vm.completedDistributionCount,
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart(JudgeDashboardVm vm) {
    return ChartCard(
      title: 'Score Distribution',
      icon: AppIcons.scoring,
      child: ResponsiveChartBox(
        desktopHeight: 210,
        child: _ScoreDistributionChart(
          lowCount: vm.lowScoreCount,
          mediumCount: vm.mediumScoreCount,
          highCount: vm.highScoreCount,
        ),
      ),
    );
  }

  Widget _buildEvaluationTimelineChart(JudgeDashboardVm vm) {
    return ChartCard(
      title: 'Evaluation Timeline',
      icon: AppIcons.clock,
      child: ResponsiveChartBox(
        desktopHeight: 210,
        child: _EvaluationTimelineChart(series: vm.evaluationTimeline),
      ),
    );
  }

  Widget _buildJudgeInfoAndWorkload(JudgeDashboardVm vm) {
    return ResponsivePair(
      spacing: ResponsiveHelper.dashboardSectionGap(context),
      secondFlex: 2,
      first: _buildJudgeInfoCard(vm),
      second: _buildWorkloadOverview(vm),
    );
  }

  Widget _buildJudgeInfoCard(JudgeDashboardVm vm) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardCardTitle(title: 'Judge Information', icon: AppIcons.judges),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          _detailRow(icon: AppIcons.judges, label: 'Judge', value: vm.judgeName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'Organization', value: vm.organizationName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Expertise', value: vm.expertise),
          const SizedBox(height: 8),
          _detailRow(
            icon: AppIcons.departments,
            label: 'Assigned Depts',
            value: vm.assignedDepartments.isEmpty ? '-' : vm.assignedDepartments.join(', '),
          ),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.statusEvaluated, label: 'Evaluations', value: '${vm.evaluatedIdeas}'),
          const SizedBox(height: 8),
          _detailRow(
            icon: AppIcons.insights,
            label: 'Avg Turnaround',
            value: vm.avgTurnaroundHours == null ? '-' : '${vm.avgTurnaroundHours!.toStringAsFixed(1)} hrs',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadOverview(JudgeDashboardVm vm) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardCardTitle(title: 'Evaluation Overview', icon: AppIcons.insights),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          LayoutBuilder(
            builder: (_, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = (maxWidth / 240).floor().clamp(1, 2);
              const spacing = 12.0;
              final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  SizedBox(
                    width: cardWidth,
                    child: _JudgeIdeaListCard(
                      title: 'Recently Evaluated',
                      emptyText: 'No evaluations yet.',
                      items: vm.recentEvaluatedIdeas,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _JudgeIdeaListCard(
                      title: 'Highest Scored',
                      emptyText: 'No scored ideas yet.',
                      items: vm.highestScoredIdeas,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _JudgeIdeaListCard(
                      title: 'Pending Evaluations',
                      emptyText: 'No pending evaluations.',
                      items: vm.pendingEvaluations,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _JudgeIdeaListCard(
                      title: 'Re-evaluation Required',
                      emptyText: 'No re-evaluations currently.',
                      items: vm.reevaluationIdeas,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(JudgeDashboardVm vm) {
    return SectionContainer(
      child: DashboardListCard(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        preset: DashboardListPreset.compact,
        headers: const <Widget>[
          DashboardCardTitle(title: 'Recent Activity', icon: AppIcons.clock),
          SizedBox(height: DashboardCardTitleStyle.headerSpacing),
        ],
        itemCount: vm.activities.length,
        empty: const Align(
          alignment: Alignment.topLeft,
          child: Text('No recent activity.'),
        ),
        itemBuilder: (BuildContext context, int index) => _activityRow(vm.activities[index]),
      ),
    );
  }

  Widget _activityRow(JudgeActivityItem activity) {
    return Row(
      children: <Widget>[
        Icon(activity.icon, size: _kActivityIconSize, color: const Color(0xFF4B5AA9)),
        const SizedBox(width: 8),
        Expanded(child: Text(activity.text)),
        Text(
          formatDateTime(activity.at),
          style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
        ),
      ],
    );
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Icon(icon, size: 16, color: const Color(0xFF57629A)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B556A), fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF4B556A))),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _JudgeStatusDonut extends StatelessWidget {
  const _JudgeStatusDonut({
    required this.pending,
    required this.completed,
  });

  final int pending;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final total = (pending + completed).clamp(1, 1 << 20);
    return Row(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.78,
            child: CustomPaint(
              painter: _JudgeStatusDonutPainter(
                pendingPct: pending / total,
                completedPct: completed / total,
              ),
              child: Center(
                child: Text(
                  '${pending + completed}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
              _LegendDot(color: StatusStyles.underReview, text: 'Pending $pending'),
              const SizedBox(height: 6),
              _LegendDot(color: StatusStyles.evaluated, text: 'Completed $completed'),
            ],
          ),
        ),
      ],
    );
  }
}

class _JudgeStatusDonutPainter extends CustomPainter {
  const _JudgeStatusDonutPainter({
    required this.pendingPct,
    required this.completedPct,
  });

  final double pendingPct;
  final double completedPct;

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

    arc(pendingPct, StatusStyles.underReview);
    arc(completedPct, StatusStyles.evaluated);
  }

  @override
  bool shouldRepaint(covariant _JudgeStatusDonutPainter oldDelegate) =>
      oldDelegate.pendingPct != pendingPct || oldDelegate.completedPct != completedPct;
}

class _ScoreDistributionChart extends StatelessWidget {
  const _ScoreDistributionChart({
    required this.lowCount,
    required this.mediumCount,
    required this.highCount,
  });

  final int lowCount;
  final int mediumCount;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    final maxValue = <int>[lowCount, mediumCount, highCount].reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _LegendDot(color: StatusStyles.rejected, text: 'Low (<4)'),
        const SizedBox(height: 6),
        const _LegendDot(color: Color(0xFFE2A428), text: 'Medium (4-6.9)'),
        const SizedBox(height: 6),
        const _LegendDot(color: StatusStyles.approved, text: 'High (>=7)'),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _ScoreBar(
                  label: 'Low',
                  value: lowCount,
                  ratio: lowCount / safeMax,
                  color: StatusStyles.rejected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBar(
                  label: 'Medium',
                  value: mediumCount,
                  ratio: mediumCount / safeMax,
                  color: const Color(0xFFE2A428),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBar(
                  label: 'High',
                  value: highCount,
                  ratio: highCount / safeMax,
                  color: StatusStyles.approved,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text('$value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio.clamp(0, 1),
              child: Container(
                width: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87))),
      ],
    );
  }
}

class _EvaluationTimelineChart extends StatelessWidget {
  const _EvaluationTimelineChart({required this.series});

  final Map<String, int> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('No evaluations yet.'));
    }
    final labels = series.keys.toList(growable: false);
    final values = series.values.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _LegendDot(color: StatusStyles.evaluated, text: 'Evaluations Completed'),
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
                  painter: _TimelineLinePainter(values: values),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Text(labels.first, style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87))),
            const Spacer(),
            Text(labels.last, style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87))),
          ],
        ),
      ],
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  const _TimelineLinePainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : i * (size.width / (values.length - 1));
      final y = size.height - ((values[i] / safeMax) * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = StatusStyles.evaluated
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);

    final dot = Paint()..color = StatusStyles.evaluated;
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : i * (size.width / (values.length - 1));
      final y = size.height - ((values[i] / safeMax) * (size.height - 10)) - 5;
      canvas.drawCircle(Offset(x, y), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) => oldDelegate.values != values;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _JudgeIdeaListCard extends StatelessWidget {
  const _JudgeIdeaListCard({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<JudgeIdeaEvaluationItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)))
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Team ${item.teamName} • ${item.problemDepartment}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5A5F87)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        _StatusPill(status: item.status),
                        const SizedBox(width: 6),
                        Text(
                          item.score > 0 ? 'Score ${item.score.toStringAsFixed(1)}' : 'Score -',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4A4F73)),
                        ),
                        const Spacer(),
                        Text(
                          formatDateTime(item.lastUpdated),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6E7394)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyles.colorForIdeaStatus(status);
    final label = status.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
