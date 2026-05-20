import 'package:flutter/material.dart';

import '../../utils/common_helpers.dart';
import '../core/workspace_attachments_summary.dart';
import 'problem_metadata_section.dart';
import 'problem_related_section.dart';
import 'problem_stats_section.dart';
import 'problem_summary_section.dart';
import 'problem_workspace.dart';

class ProblemWorkspaceBody extends StatelessWidget {
  const ProblemWorkspaceBody({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final vm = this.vm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
      children: <Widget>[
        ProblemSummarySection(vm: vm),
        const SizedBox(height: 14),
        ProblemMetadataSection(
          vm: vm,
          onOpenCreator: vm.createdByUserId.trim().isEmpty
              ? null
              : () => ProblemWorkspace.openUserFromProblem(context, vm.createdByUserId),
        ),
        const SizedBox(height: 14),
        ProblemStatsSection(vm: vm),
        const SizedBox(height: 14),
        WorkspaceAttachmentsSummary(
          counts: vm.attachmentCounts,
          emptyMessage: 'No attachments uploaded for this problem.',
        ),
        const SizedBox(height: 14),
        ProblemRelatedSection(
          vm: vm,
          onOpenIdea: (preview) => ProblemWorkspace.openIdeaFromProblem(context, preview),
          onOpenUser: (userId) => ProblemWorkspace.openUserFromProblem(context, userId),
        ),
        const SizedBox(height: 8),
        Text(
          'Created ${formatDateTime(vm.problem.createdAt)}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
