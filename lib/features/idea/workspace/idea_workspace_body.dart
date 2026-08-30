import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_attachments_panel.dart';
import '../../../core/workspace/workspace_theme.dart';
import 'idea_related_section.dart';
import 'idea_status_section.dart';
import 'idea_summary_section.dart';
import 'idea_workspace_loader.dart';

class IdeaWorkspaceBody extends StatelessWidget {
  const IdeaWorkspaceBody({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final vm = this.vm;
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        IdeaSummarySection(vm: vm),
        const SizedBox(height: 14),
        IdeaStatusSection(vm: vm),
        const SizedBox(height: 14),
        IdeaRelatedSection(vm: vm),
        const SizedBox(height: 14),
        WorkspaceAttachmentsPanel(
          attachments: vm.attachments,
          emptyMessage: 'No attachments uploaded for this proposal yet.',
        ),
      ],
    );
  }
}
