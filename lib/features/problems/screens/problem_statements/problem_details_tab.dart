import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.only(bottom: 20),
      children: <Widget>[
        ProblemSummarySection(
          vm: vm,
          showMetaChips: false,
          prominentDescription: true,
          stackContextFieldLabels: true,
        ),
        const SizedBox(height: 16),
        ProblemMetadataSection(vm: vm),
        const SizedBox(height: 16),
        WorkspaceAttachmentsPanel(
          attachments: vm.attachments,
          emptyMessage: 'No attachments uploaded for this problem statement.',
        ),
      ],
    );
  }
}
