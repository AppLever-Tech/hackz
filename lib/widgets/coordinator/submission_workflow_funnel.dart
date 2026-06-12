import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/coordinator_dashboard_service.dart';
import '../../core/ui/common/dashboard_trend_chart_layout.dart';

class SubmissionWorkflowFunnel extends StatelessWidget {
  const SubmissionWorkflowFunnel({super.key, required this.steps});

  final List<SubmissionWorkflowStep> steps;

  @override
  Widget build(BuildContext context) {
    final int maxCount = steps.fold<int>(
      0,
      (int max, SubmissionWorkflowStep step) => step.count > max ? step.count : max,
    );
    final String subtitle = steps.any((SubmissionWorkflowStep s) => s.label == 'Ideas Created')
        ? 'Processing visibility from idea creation to official submission'
        : 'Payment verification pipeline for your department';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const DashboardCardTitle(
          title: 'Submission Workflow Funnel',
          icon: AppIcons.submissions,
        ),
        const SizedBox(height: DashboardTrendChartLayout.headerToSubtitleGap),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
        ..._buildStepRows(maxCount),
      ],
    );
  }

  List<Widget> _buildStepRows(int maxCount) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      if (i > 0) {
        rows.add(const SizedBox(height: 12));
      }
      rows.add(_stepRow(steps[i], maxCount));
    }
    return rows;
  }

  Widget _stepRow(SubmissionWorkflowStep step, int maxCount) {
    final double widthFactor =
        maxCount == 0 ? 0.08 : (step.count / maxCount).clamp(0.08, 1.0).toDouble();
    return Row(
      children: <Widget>[
        SizedBox(
          width: 138,
          child: Text(
            step.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: <Widget>[
                Container(height: 30, color: const Color(0xFFF1F5F9)),
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          step.color.withValues(alpha: 0.72),
                          step.color,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${step.count}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
