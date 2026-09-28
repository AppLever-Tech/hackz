import 'package:flutter/material.dart';

import '../../../core/theme/status_styles.dart';
import '../../../utils/common_helpers.dart';
import 'idea_workspace_loader.dart';

/// Read-only workflow context for the innovation proposal (no actions).
class IdeaStatusSection extends StatelessWidget {
  const IdeaStatusSection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.idea;
    final Color accent = StatusStyles.colorForIdeaStatus(idea.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Submission status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: 0.08),
                const Color(0xFFF8FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: <Widget>[
              StatusStyles.ideaStatusIcon(idea.status, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ideaWorkspaceStatusLabel(idea.status),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${formatDateTime(idea.createdAt)} · ${vm.submittedByName}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
