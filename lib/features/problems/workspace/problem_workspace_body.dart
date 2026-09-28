import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_attachments_panel.dart';
import '../../../core/workspace/workspace_theme.dart';
import 'problem_metadata_section.dart';
import 'problem_related_section.dart';
import 'problem_summary_section.dart';
import 'problem_workspace.dart';

class ProblemWorkspaceBody extends StatelessWidget {
  const ProblemWorkspaceBody({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final vm = this.vm;
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        ProblemSummarySection(vm: vm, workspaceSectionsOnly: true),
        const SizedBox(height: 14),
        ProblemMetadataSection(
          vm: vm,
          onOpenCreator: vm.createdByUserId.trim().isEmpty
              ? null
              : () => ProblemWorkspace.openUserFromProblem(context, vm.createdByUserId),
        ),
        const SizedBox(height: 14),
        WorkspaceAttachmentsPanel(
          attachments: vm.attachments,
          emptyMessage: 'No attachments uploaded for this problem.',
        ),
        const SizedBox(height: 14),
        ProblemRelatedSection(
          vm: vm,
          onOpenIdea: (preview) => ProblemWorkspace.openIdeaFromProblem(context, preview),
          onOpenUser: (userId) => ProblemWorkspace.openUserFromProblem(context, userId),
        ),
      ],
    );
  }
}
