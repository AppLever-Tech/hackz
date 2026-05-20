import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/idea_model.dart';
import 'problem_workspace.dart';

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
                InkWell(
                  onTap: () => onOpenIdea(preview),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_statusLabel(preview.idea.status)} · $scoreText',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: preview.createdByUserId.trim().isEmpty
                      ? null
                      : () => onOpenUser(preview.createdByUserId),
                  child: Text(
                    'By ${preview.createdByName}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w700),
                  ),
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

class ProblemIdeaPreviewRoute extends StatelessWidget {
  const ProblemIdeaPreviewRoute({
    super.key,
    required this.preview,
    this.onOpenCreator,
  });

  final ProblemIdeaPreview preview;
  final VoidCallback? onOpenCreator;

  @override
  Widget build(BuildContext context) {
    final idea = preview.idea;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Text(
          idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : idea.ideaTitle.trim(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _pill(AppIcons.statusUnderReview, _statusLabel(idea.status)),
            _pill(AppIcons.scoring, preview.avgScore == null ? 'No score' : 'Avg ${preview.avgScore!.toStringAsFixed(1)}'),
            _pill(AppIcons.clock, '${idea.createdAt.day}/${idea.createdAt.month}/${idea.createdAt.year}'),
          ],
        ),
        const SizedBox(height: 12),
        if (idea.description.trim().isNotEmpty)
          Text(
            idea.description.trim(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
          ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onOpenCreator,
          child: Text(
            'Created by ${preview.createdByName}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  static Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF57629A)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
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
