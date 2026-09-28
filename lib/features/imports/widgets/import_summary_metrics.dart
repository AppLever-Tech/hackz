import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../models/import_summary.dart';

class ImportSummaryMetrics extends StatelessWidget {
  const ImportSummaryMetrics({
    super.key,
    required this.summary,
    this.compactSingleRow = false,
  });

  final ImportSummary summary;
  final bool compactSingleRow;

  @override
  Widget build(BuildContext context) {
    final List<DashboardMetricChipData> chips = summary.previewCounts.isEmpty
        ? _defaultChips(summary)
        : summary.previewCounts.map(_chipForPreview).toList(growable: false);

    return ResponsiveMetricGrid(
      spacing: compactSingleRow ? 6 : 10,
      runSpacing: compactSingleRow ? 6 : 10,
      maxDesktopColumns: compactSingleRow ? chips.length : null,
      compact: compactSingleRow,
      chips: chips,
    );
  }

  static List<DashboardMetricChipData> _defaultChips(ImportSummary summary) {
    return <DashboardMetricChipData>[
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
        icon: AppIcons.workflowRejected,
      ),
    ];
  }

  static DashboardMetricChipData _chipForPreview(ImportPreviewCount count) {
    final (Color color, IconData icon) = _lookFor(count.label);
    return DashboardMetricChipData.single(
      label: count.label,
      value: '${count.value}',
      color: color,
      icon: icon,
    );
  }

  static (Color, IconData) lookFor(String label) => _lookFor(label);

  static (Color, IconData) _lookFor(String label) {
    return switch (label) {
      'Teams' => (const Color(0xFF4A67FF), AppIcons.teams),
      'Members' => (const Color(0xFF6A38FF), AppIcons.teamMember),
      'Team Leaders' => (const Color(0xFF0EA5E9), AppIcons.users),
      'Existing Users' => (const Color(0xFF047857), AppIcons.workflowApproved),
      'New Users' => (const Color(0xFF7C3AED), AppIcons.teamMember),
      'Warnings' => (const Color(0xFFEA580C), AppIcons.info),
      'Needs review' => (const Color(0xFFEA580C), AppIcons.info),
      'Invalid' => (const Color(0xFFB91C1C), AppIcons.workflowRejected),
      'Extracted' => (const Color(0xFF4A67FF), AppIcons.problems),
      'Valid' => (const Color(0xFF047857), AppIcons.workflowApproved),
      'Errors' => (const Color(0xFFB91C1C), AppIcons.workflowRejected),
      'Updates' => (const Color(0xFF7C3AED), AppIcons.refresh),
      _ => (const Color(0xFF4A67FF), AppIcons.attachments),
    };
  }
}
