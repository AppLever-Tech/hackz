import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import '../core/workspace_attachments_summary.dart';
import 'idea_metrics_section.dart';
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
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    return ListView(
      padding: pad,
      children: <Widget>[
        IdeaSummarySection(vm: vm),
        const SizedBox(height: 14),
        IdeaStatusSection(vm: vm),
        const SizedBox(height: 14),
        IdeaMetricsSection(vm: vm),
        const SizedBox(height: 14),
        IdeaRelatedSection(vm: vm),
        const SizedBox(height: 14),
        WorkspaceAttachmentsSummary(
          counts: vm.attachmentCounts,
          emptyMessage: 'No attachments uploaded for this proposal yet.',
        ),
      ],
    );
  }
}
