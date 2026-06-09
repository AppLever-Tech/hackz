import 'package:flutter/material.dart';

import '../../../../screens/common/dashboard_components.dart';
import '../../../../core/workspace/workspace_attachments_panel.dart';
import '../../workspace/problem_metadata_section.dart';
import '../../workspace/problem_summary_section.dart';
import '../../workspace/problem_workspace_loader.dart';

/// Problem Details tab for [ProblemStatementDetailsScreen].
class ProblemDetailsTab extends StatelessWidget {
  const ProblemDetailsTab({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: ProblemSummarySection(
            vm: vm,
            showMetaChips: false,
            prominentDescription: true,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: ProblemMetadataSection(vm: vm),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: WorkspaceAttachmentsPanel(
            attachments: vm.attachments,
            emptyMessage: 'No attachments uploaded for this problem statement.',
          ),
        ),
      ],
    );
  }
}
