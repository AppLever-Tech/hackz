import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../services/ideathon_readiness_service.dart';

/// Shows shortlisted count vs org threshold and optional create action.
class IdeathonReadinessBanner extends StatelessWidget {
  const IdeathonReadinessBanner({
    super.key,
    required this.readiness,
    this.onCreateIdeathon,
    this.busy = false,
  });

  final IdeathonReadiness readiness;
  final VoidCallback? onCreateIdeathon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool ready = readiness.isReady;
    final Color accent = ready ? const Color(0xFF059669) : const Color(0xFFEA580C);
    final String message = ready
        ? 'Ready for Ideathon'
        : '${readiness.shortlistedCount} / ${readiness.requiredCount} Shortlisted';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Icon(ready ? Icons.check_circle_rounded : AppIcons.ideathons, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
                ),
                const SizedBox(height: 2),
                Text(
                  ready
                      ? 'Minimum shortlisted ideas reached. You can create an ideathon event.'
                      : 'Shortlist more ideas to unlock ideathon creation.',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (ready && onCreateIdeathon != null) ...<Widget>[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: busy ? null : onCreateIdeathon,
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(AppIcons.add, size: 16),
              label: const Text('Create Ideathon'),
            ),
          ],
        ],
      ),
    );
  }
}
