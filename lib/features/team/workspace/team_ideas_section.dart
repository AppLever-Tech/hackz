import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/status_styles.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../models/payment_model.dart';
import '../../../widgets/common/context_pill.dart';
import '../../../widgets/common/context_pill_theme.dart';
import 'team_workspace.dart';
import 'team_workspace_loader.dart';

class TeamIdeasSection extends StatelessWidget {
  const TeamIdeasSection({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Ideas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        if (vm.ideas.isEmpty)
          const Text(
            'No ideas submitted by this team yet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          )
        else
          ...vm.ideas.map((TeamIdeaPreview preview) => _ideaRow(context, preview)),
      ],
    );
  }

  Widget _ideaRow(BuildContext context, TeamIdeaPreview preview) {
    final String title =
        preview.idea.ideaTitle.trim().isEmpty ? preview.idea.ideaId : preview.idea.ideaTitle.trim();
    final String scoreText =
        preview.avgScore == null ? 'No score' : 'Avg ${preview.avgScore!.toStringAsFixed(1)}';
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
                    onTap: () => TeamWorkspace.openIdeaFromTeam(context, preview),
                    compact: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    _statusChip(preview.idea.status),
                    _scoreChip(scoreText, preview.avgScore != null),
                    if (preview.paymentStatus != null) _paymentChip(preview.paymentStatus!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(IdeaStatus status) {
    final Color color = StatusStyles.colorForIdeaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(StatusStyles.iconForIdeaStatus(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            StatusStyles.labelForIdeaStatus(status),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  static Widget _scoreChip(String text, bool hasScore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasScore ? const Color(0xFFE7F9F1) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: hasScore ? const Color(0xFF177C50) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  static Widget _paymentChip(PaymentRecordStatus status) {
    final String label = switch (status) {
      PaymentRecordStatus.pending => 'Payment pending',
      PaymentRecordStatus.verified => 'Payment verified',
      PaymentRecordStatus.rejected => 'Payment rejected',
    };
    final Color color = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFB56A11),
      PaymentRecordStatus.verified => const Color(0xFF177C50),
      PaymentRecordStatus.rejected => const Color(0xFFB93838),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
