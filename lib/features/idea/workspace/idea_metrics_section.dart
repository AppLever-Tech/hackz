import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import 'idea_workspace_loader.dart';

class IdeaMetricsSection extends StatelessWidget {
  const IdeaMetricsSection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final String score = vm.averageScore == null ? '—' : vm.averageScore!.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Innovation metrics',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        DashboardMetricChipGrid(
          spacing: 10,
          runSpacing: 10,
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Score',
              value: score,
              color: const Color(0xFF7C3AED),
              icon: AppIcons.scoring,
            ),
            DashboardMetricChipData.single(
              label: 'Evaluation',
              value: vm.evaluationProgressLabel,
              color: const Color(0xFF4A67FF),
              icon: AppIcons.statusEvaluated,
            ),
            DashboardMetricChipData.single(
              label: 'Payment',
              value: vm.paymentStatusLabel,
              color: const Color(0xFFEA580C),
              icon: AppIcons.payments,
            ),
            DashboardMetricChipData.single(
              label: 'Reviewers',
              value: '${vm.reviewerCount}',
              color: const Color(0xFF0EA5E9),
              icon: AppIcons.judges,
            ),
            DashboardMetricChipData.single(
              label: 'Attachments',
              value: '${vm.attachmentCount}',
              color: const Color(0xFF16A34A),
              icon: AppIcons.attachments,
            ),
          ],
        ),
      ],
    );
  }
}
