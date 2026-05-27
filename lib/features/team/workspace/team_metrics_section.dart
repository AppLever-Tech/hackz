import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import 'team_workspace_loader.dart';

class TeamMetricsSection extends StatelessWidget {
  const TeamMetricsSection({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final String avg = vm.averageScore == null ? '—' : vm.averageScore!.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Metrics',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        DashboardMetricChipGrid(
          spacing: 10,
          runSpacing: 10,
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Active ideas',
              value: '${vm.activeIdeas}',
              color: const Color(0xFF4A67FF),
              icon: AppIcons.ideas,
            ),
            DashboardMetricChipData.single(
              label: 'Approved',
              value: '${vm.approvedIdeas}',
              color: const Color(0xFF16A34A),
              icon: AppIcons.statusApproved,
            ),
            DashboardMetricChipData.single(
              label: 'Evaluated',
              value: '${vm.evaluatedIdeas}',
              color: const Color(0xFF7C3AED),
              icon: AppIcons.scoring,
            ),
            DashboardMetricChipData.single(
              label: 'Avg score',
              value: avg,
              color: const Color(0xFF0EA5E9),
              icon: AppIcons.scoring,
            ),
          ],
        ),
      ],
    );
  }
}
