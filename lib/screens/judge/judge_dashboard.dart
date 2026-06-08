import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../features/user/models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/judge_dashboard_service.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/common/dashboard_card/dashboard_card_layout.dart';
import '../../widgets/common/dashboard_trend_chart_layout.dart';
import '../../widgets/common/time_frame_filter.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
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

enum _JudgeDashboardTimeframe {
  currentWeek('Current week'),
  lastWeek('Last week'),
  lastMonth('Last month'),
  lastSixMonths('Last 6 months'),
  all('All');

  const _JudgeDashboardTimeframe(this.label);
  final String label;
}

class _JudgeDashboardHome extends StatefulWidget {
  const _JudgeDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_JudgeDashboardHome> createState() => _JudgeDashboardHomeState();
}

class _JudgeDashboardHomeState extends State<_JudgeDashboardHome> {
  static const int _kChartRowFirstFlex = 3;
  static const int _kChartRowSecondFlex = 2;
  static const double _kActivityIconSize = 18;

  final JudgeDashboardService _service = JudgeDashboardService();
  late Future<JudgeDashboardVm> _future;
  _JudgeDashboardTimeframe _timelineTimeframe = _JudgeDashboardTimeframe.currentWeek;
  _JudgeDashboardTimeframe _activityTimeframe = _JudgeDashboardTimeframe.currentWeek;

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
              _buildChartsRow(context, vm, gap),
              SizedBox(height: gap),
              _buildOverviewAndActivityRow(context, vm, gap),
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
          icon: AppIcons.statusUnderEvaluation,
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

  Widget _buildChartsRow(BuildContext context, JudgeDashboardVm vm, double gap) {
    final Map<String, int> timelineSeries =
        _buildTimeSeries(vm.evaluationDates, _timelineTimeframe);
    return DashboardPairRow(
      height: DashboardLayoutTokens.trendCardContentHeight +
          DashboardLayoutTokens.sectionContainerVerticalPadding,
      pair: ResponsivePair(
        spacing: gap,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        firstFlex: _kChartRowFirstFlex,
        secondFlex: _kChartRowSecondFlex,
        first: SectionContainer(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DashboardCardHeaderRow(
                title: 'Evaluation Timeline',
                icon: AppIcons.clock,
                trailing: TimeFrameFilter<_JudgeDashboardTimeframe>(
                  options: _JudgeDashboardTimeframe.values,
                  selected: _timelineTimeframe,
                  labelBuilder: (_JudgeDashboardTimeframe option) => option.label,
                  onChanged: (_JudgeDashboardTimeframe timeframe) =>
                      setState(() => _timelineTimeframe = timeframe),
                ),
              ),
              const SizedBox(height: DashboardTrendChartLayout.headerToSubtitleGap),
              Text(
                '${_timelineTimeframe.label} evaluations completed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
              SizedBox(
                height: DashboardTrendChartLayout.chartBoxHeight,
                child: _JudgeEvaluationTimelineChart(series: timelineSeries),
              ),
              const SizedBox(height: DashboardTrendChartLayout.chartToLegendGap),
              const _LegendDot(color: StatusStyles.evaluated, text: 'Evaluations completed'),
            ],
          ),
        ),
        second: SectionContainer(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: DashboardStackedChartBody(
            headers: <Widget>[
              const DashboardCardTitle(title: 'Score Distribution', icon: AppIcons.scoring),
              const SizedBox(height: DashboardLayoutTokens.chartHeaderSpacing),
            ],
            chart: _ScoreDistributionChart(
              lowCount: vm.lowScoreCount,
              mediumCount: vm.mediumScoreCount,
              highCount: vm.highScoreCount,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewAndActivityRow(BuildContext context, JudgeDashboardVm vm, double gap) {
    return DashboardPairRow(
      height: DashboardLayoutTokens.pairRowAlertsActivity,
      pair: ResponsivePair(
        spacing: gap,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        firstFlex: _kChartRowFirstFlex,
        secondFlex: _kChartRowSecondFlex,
        first: _buildWorkloadOverview(vm),
        second: _buildRecentActivity(vm),
      ),
    );
  }

  Widget _buildWorkloadOverview(JudgeDashboardVm vm) {
    return SectionContainer(
      child: DashboardBoundedBody(
        headers: <Widget>[
          const DashboardCardTitle(title: 'Evaluation Overview', icon: AppIcons.insights),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
        ],
        bodyBuilder: ({required bool expandVertically}) {
          return LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = (maxWidth / 240).floor().clamp(1, 2);
              const spacing = 12.0;
              final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
              final Widget grid = Wrap(
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
              if (expandVertically) {
                return SingleChildScrollView(child: grid);
              }
              return grid;
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentActivity(JudgeDashboardVm vm) {
    final filtered = vm.activities
        .where((JudgeActivityItem activity) => _isWithinTimeframe(activity.at, _activityTimeframe))
        .toList(growable: false);
    return SectionContainer(
      child: DashboardListCard(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        preset: DashboardListPreset.compact,
        headers: <Widget>[
          DashboardCardHeaderRow(
            title: 'Recent Activity',
            icon: AppIcons.clock,
            trailing: TimeFrameFilter<_JudgeDashboardTimeframe>(
              options: _JudgeDashboardTimeframe.values,
              selected: _activityTimeframe,
              labelBuilder: (_JudgeDashboardTimeframe option) => option.label,
              onChanged: (_JudgeDashboardTimeframe timeframe) =>
                  setState(() => _activityTimeframe = timeframe),
            ),
          ),
          const SizedBox(height: DashboardLayoutTokens.activityHeaderGap),
        ],
        itemCount: filtered.length,
        empty: const Align(
          alignment: Alignment.topLeft,
          child: Text('No activity in this period.'),
        ),
        itemBuilder: (BuildContext context, int index) => _activityRow(filtered[index]),
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

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  Map<String, int> _buildTimeSeries(Iterable<DateTime> source, _JudgeDashboardTimeframe timeframe) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    late final DateTime start;
    late final DateTime end;
    late final int bucketCount;
    late final Duration bucketSize;
    switch (timeframe) {
      case _JudgeDashboardTimeframe.currentWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case _JudgeDashboardTimeframe.lastWeek:
        end = today.subtract(Duration(days: today.weekday - 1));
        start = end.subtract(const Duration(days: 7));
        bucketCount = 7;
        bucketSize = const Duration(days: 1);
        break;
      case _JudgeDashboardTimeframe.lastMonth:
        start = today.subtract(const Duration(days: 30));
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 5);
        break;
      case _JudgeDashboardTimeframe.lastSixMonths:
        start = DateTime(today.year, today.month - 5, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 6;
        bucketSize = const Duration(days: 31);
        break;
      case _JudgeDashboardTimeframe.all:
        final dates = source.toList(growable: false)..sort();
        start = dates.isEmpty
            ? today.subtract(const Duration(days: 180))
            : DateTime(dates.first.year, dates.first.month, 1);
        end = now.add(const Duration(days: 1));
        bucketCount = 8;
        final days = end.difference(start).inDays.clamp(1, 3650).toInt();
        bucketSize = Duration(days: (days / bucketCount).ceil().clamp(1, 365).toInt());
        break;
    }

    final buckets =
        List<DateTime>.generate(bucketCount, (int i) => start.add(Duration(days: bucketSize.inDays * i)));
    final dates = source.map(_dateOnly).toList(growable: false);
    return <String, int>{
      for (int i = 0; i < buckets.length; i++)
        _bucketLabel(buckets[i], timeframe): dates.where((DateTime date) {
          final DateTime from = _dateOnly(buckets[i]);
          final DateTime to = _dateOnly(i == buckets.length - 1 ? end : buckets[i + 1]);
          return !date.isBefore(from) && date.isBefore(to);
        }).length,
    };
  }

  bool _isWithinTimeframe(DateTime date, _JudgeDashboardTimeframe timeframe) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final DateTime when = _dateOnly(date);
    switch (timeframe) {
      case _JudgeDashboardTimeframe.currentWeek:
        final DateTime start = today.subtract(Duration(days: today.weekday - 1));
        return !when.isBefore(start) && when.isBefore(start.add(const Duration(days: 7)));
      case _JudgeDashboardTimeframe.lastWeek:
        final DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
        final DateTime start = currentWeekStart.subtract(const Duration(days: 7));
        return !when.isBefore(start) && when.isBefore(currentWeekStart);
      case _JudgeDashboardTimeframe.lastMonth:
        return !when.isBefore(today.subtract(const Duration(days: 30)));
      case _JudgeDashboardTimeframe.lastSixMonths:
        return !when.isBefore(DateTime(today.year, today.month - 5, 1));
      case _JudgeDashboardTimeframe.all:
        return true;
    }
  }

  String _bucketLabel(DateTime date, _JudgeDashboardTimeframe timeframe) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    switch (timeframe) {
      case _JudgeDashboardTimeframe.currentWeek:
      case _JudgeDashboardTimeframe.lastWeek:
        const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      case _JudgeDashboardTimeframe.lastMonth:
        return '${date.month}/${date.day}';
      case _JudgeDashboardTimeframe.lastSixMonths:
        return months[date.month - 1];
      case _JudgeDashboardTimeframe.all:
        return '${months[date.month - 1]} ${date.year % 100}';
    }
  }
}

class _JudgeEvaluationTimelineChart extends StatelessWidget {
  const _JudgeEvaluationTimelineChart({required this.series});

  final Map<String, int> series;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = series.values.every((int value) => value == 0);
    if (series.isEmpty || isEmpty) {
      return const Center(child: Text('No evaluations in this period.'));
    }
    return CustomPaint(
      painter: _JudgeEvaluationTimelinePainter(series: series),
      child: const SizedBox.expand(),
    );
  }
}

class _JudgeEvaluationTimelinePainter extends CustomPainter {
  const _JudgeEvaluationTimelinePainter({required this.series});

  final Map<String, int> series;

  @override
  void paint(Canvas canvas, Size size) {
    final List<String> labels = series.keys.toList(growable: false);
    final List<int> values = series.values.toList(growable: false);
    if (labels.isEmpty) return;

    final Rect plot = DashboardTrendChartLayout.plotRect(size);
    final Paint grid = Paint()
      ..color = const Color(0xFFE8ECF8)
      ..strokeWidth = 1;
    for (int i = 0; i <= DashboardTrendChartLayout.yAxisTickCount; i++) {
      final double y = DashboardTrendChartLayout.yAxisLineY(plot, i);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final int maxValue = math.max(1, values.fold<int>(0, math.max));
    final Paint stroke = Paint()
      ..color = StatusStyles.evaluated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint dot = Paint()..color = StatusStyles.evaluated;
    final Path path = Path();

    for (int i = 0; i < values.length; i++) {
      final double x =
          values.length == 1 ? plot.center.dx : plot.left + (plot.width * i / (values.length - 1));
      final double y = plot.bottom - (values[i] / maxValue) * plot.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.2, dot);
    }
    canvas.drawPath(path, stroke);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      final double x =
          values.length == 1 ? plot.center.dx : plot.left + (plot.width * i / (values.length - 1));
      tp.text = TextSpan(text: labels[i], style: DashboardTrendChartLayout.axisLabelStyle);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + DashboardTrendChartLayout.xLabelGap));
    }
    for (int i = 0; i <= DashboardTrendChartLayout.yAxisTickCount; i++) {
      final int value = DashboardTrendChartLayout.yAxisValue(maxValue, i);
      final double y = DashboardTrendChartLayout.yAxisLineY(plot, i);
      tp.text = TextSpan(text: '$value', style: DashboardTrendChartLayout.axisLabelStyle);
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _JudgeEvaluationTimelinePainter oldDelegate) =>
      oldDelegate.series != series;
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
                  color: color.withValues(alpha: 0.85),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
