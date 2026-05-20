import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
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
        _previewCard(
          context,
          icon: AppIcons.problems,
          title: 'Problem',
          headline: vm.problemTitle,
          detail: vm.problem.departmentDisplayName,
          onTap: vm.problem.problemId.trim().isEmpty && vm.idea.problemId.trim().isEmpty
              ? null
              : () => IdeaWorkspace.openProblemFromIdea(context, vm),
        ),
        _previewCard(
          context,
          icon: AppIcons.teams,
          title: 'Team',
          headline: vm.teamName,
          detail: 'Mentor · ${vm.mentorName}',
          onTap: vm.team.teamId.trim().isEmpty && vm.idea.teamId.trim().isEmpty
              ? null
              : () => IdeaWorkspace.openTeamFromIdea(context, vm),
        ),
        _previewCard(
          context,
          icon: AppIcons.payments,
          title: 'Payment',
          headline: vm.paymentStatusLabel,
          detail: vm.payment == null
              ? 'No payment record for this idea'
              : '₹${vm.payment!.amount.toStringAsFixed(0)} · ${formatDateTime(vm.payment!.createdAt)}',
          onTap: vm.payment == null ? null : () => IdeaWorkspace.openPaymentFromIdea(context, vm),
        ),
        _previewCard(
          context,
          icon: AppIcons.scoring,
          title: 'Evaluation',
          headline: vm.averageScore == null ? 'Not scored yet' : 'Avg ${vm.averageScore!.toStringAsFixed(1)} / 10',
          detail: vm.evaluationProgressLabel,
          onTap: vm.scores.isEmpty ? null : () => IdeaWorkspace.openEvaluationFromIdea(context, vm),
        ),
      ],
    );
  }

  Widget _previewCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String headline,
    required String detail,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF57629A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: onTap == null ? const Color(0xFF64748B) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(AppIcons.openInNew, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
