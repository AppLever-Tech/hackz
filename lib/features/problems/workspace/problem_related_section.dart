import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/idea_model.dart';
import '../../../widgets/common/context_pill.dart';
import '../../../widgets/common/context_pill_theme.dart';
import 'problem_workspace_loader.dart';

class ProblemRelatedSection extends StatelessWidget {
  const ProblemRelatedSection({
    super.key,
    required this.vm,
    required this.onOpenIdea,
    required this.onOpenUser,
  });

  final ProblemWorkspaceViewModel vm;
  final ValueChanged<ProblemIdeaPreview> onOpenIdea;
  final ValueChanged<String> onOpenUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Related previews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (vm.topIdeas.isEmpty)
          const Text('No submitted ideas for this problem yet.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
        else
          ...vm.topIdeas.map((idea) => _ideaTile(idea)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _summaryPill(AppIcons.departments, 'Department', vm.problem.departmentDisplayName),
            _summaryPill(AppIcons.coordinator, 'Coordinators', '${vm.coordinatorCount}'),
            _summaryPill(AppIcons.judges, 'Judges', '${vm.judgeCount}'),
          ],
        ),
      ],
    );
  }

  Widget _ideaTile(ProblemIdeaPreview preview) {
    final String title = preview.idea.ideaTitle.trim().isEmpty ? preview.idea.ideaId : preview.idea.ideaTitle.trim();
    final String scoreText = preview.avgScore == null ? 'No score' : 'Avg ${preview.avgScore!.toStringAsFixed(1)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(AppIcons.ideas, size: 16, color: Color(0xFF57629A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: title,
                    semantic: ContextPillSemantic.idea,
                    onTap: () => onOpenIdea(preview),
                    compact: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_statusLabel(preview.idea.status)} · $scoreText',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (preview.createdByUserId.trim().isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ContextPill(
                      label: preview.createdByName,
                      semantic: ContextPillSemantic.user,
                      onTap: () => onOpenUser(preview.createdByUserId),
                      compact: true,
                    ),
                  )
                else
                  Text(
                    'By ${preview.createdByName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF57629A)),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.pendingSubmission => 'Pending',
    IdeaStatus.submitted => 'Submitted',
    IdeaStatus.underReview => 'Under review',
    IdeaStatus.evaluated => 'Evaluated',
    IdeaStatus.approved => 'Approved',
    IdeaStatus.rejected => 'Rejected',
  };
}
