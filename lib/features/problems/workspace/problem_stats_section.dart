import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import 'problem_workspace.dart';

class ProblemStatsSection extends StatelessWidget {
  const ProblemStatsSection({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final int evalPct = vm.totalIdeas == 0 ? 0 : ((vm.evaluatedIdeas / vm.totalIdeas) * 100).round();
    final int payPct = vm.totalPayments == 0 ? 0 : ((vm.verifiedPayments / vm.totalPayments) * 100).round();
    return DashboardMetricChipGrid(
      spacing: 10,
      runSpacing: 10,
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Ideas',
          value: '${vm.ideasSubmitted}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Ideathon Assigned',
          value: '${vm.approvedIdeas}',
          color: const Color(0xFF16A34A),
          icon: AppIcons.statusIdeathonAssigned,
        ),
        DashboardMetricChipData.ratio(
          label: 'Evaluation',
          primary: '${vm.evaluatedIdeas}/${vm.totalIdeas}',
          secondary: '$evalPct%',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.scoring,
        ),
        DashboardMetricChipData.ratio(
          label: 'Payments',
          primary: '${vm.verifiedPayments}/${vm.totalPayments}',
          secondary: '$payPct%',
          color: const Color(0xFFEA580C),
          icon: AppIcons.payments,
        ),
      ],
    );
  }
}
