import 'package:flutter/material.dart';

import '../../utils/common_helpers.dart';
import '../../widgets/common/context_pill_theme.dart';
import '../shared/entity_reference_tile.dart';
import 'idea_workspace.dart';
import 'idea_workspace_loader.dart';

class IdeaRelatedSection extends StatelessWidget {
  const IdeaRelatedSection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Related context',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        EntityReferenceTile(
          category: 'Problem',
          headline: vm.problemTitle,
          detail: vm.problem.departmentDisplayName,
          semantic: ContextPillSemantic.problem,
          onOpenWorkspace: vm.problem.problemId.trim().isEmpty && vm.idea.problemId.trim().isEmpty
              ? null
              : () => IdeaWorkspace.openProblemFromIdea(context, vm),
        ),
        EntityReferenceTile(
          category: 'Team',
          headline: vm.teamName,
          detail: 'Mentor · ${vm.mentorName}',
          semantic: ContextPillSemantic.team,
          onOpenWorkspace: vm.team.teamId.trim().isEmpty && vm.idea.teamId.trim().isEmpty
              ? null
              : () => IdeaWorkspace.openTeamFromIdea(context, vm),
        ),
        EntityReferenceTile(
          category: 'Payment',
          headline: vm.paymentStatusLabel,
          detail: vm.payment == null
              ? 'No payment record for this idea'
              : '₹${vm.payment!.amount.toStringAsFixed(0)} · ${formatDateTime(vm.payment!.createdAt)}',
          semantic: ContextPillSemantic.payment,
          onOpenWorkspace: vm.payment == null ? null : () => IdeaWorkspace.openPaymentFromIdea(context, vm),
        ),
        EntityReferenceTile(
          category: 'Evaluation',
          headline: vm.averageScore == null ? 'Not scored yet' : 'Avg ${vm.averageScore!.toStringAsFixed(1)} / 10',
          detail: vm.evaluationProgressLabel,
          semantic: ContextPillSemantic.evaluation,
          onOpenWorkspace: vm.scores.isEmpty ? null : () => IdeaWorkspace.openEvaluationFromIdea(context, vm),
        ),
      ],
    );
  }
}
