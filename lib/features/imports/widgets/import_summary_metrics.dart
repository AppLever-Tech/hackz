import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../models/import_summary.dart';

class ImportSummaryMetrics extends StatelessWidget {
  const ImportSummaryMetrics({super.key, required this.summary});

  final ImportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMetricGrid(
      spacing: 10,
      runSpacing: 10,
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Rows',
          value: '${summary.totalRows}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.attachments,
        ),
        DashboardMetricChipData.single(
          label: 'Valid Rows',
          value: '${summary.validRows}',
          color: const Color(0xFF047857),
          icon: AppIcons.workflowApproved,
        ),
        DashboardMetricChipData.single(
          label: 'Warnings',
          value: '${summary.warningRows}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.info,
        ),
        DashboardMetricChipData.single(
          label: 'Errors',
          value: '${summary.errorRows}',
          color: const Color(0xFFB91C1C),
          icon: AppIcons.statusRejected,
        ),
      ],
    );
  }
}
