import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../events/models/event_kind.dart';
import '../../events/widgets/event_meta_chip.dart';
import '../../ideathons/widgets/ideathon_status_pill.dart';
import 'judge_event_grouping.dart';

/// Premium event section header for judge scoring queues.
class JudgeEvaluationEventHeader extends StatelessWidget {
  const JudgeEvaluationEventHeader({
    super.key,
    required this.section,
    this.expanded = true,
    this.onToggle,
  });

  final JudgeEventSection section;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final EventKind kind = section.kind;
    final Widget body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(kind.icon, size: 18, color: const Color(0xFF6A38FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (onToggle != null) ...<Widget>[
                const SizedBox(width: 8),
                Icon(
                  expanded ? AppIcons.expandLess : AppIcons.expandMore,
                  size: 22,
                  color: const Color(0xFF64748B),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (section.schedule.isNotEmpty)
                EventMetaChip(
                  icon: AppIcons.event,
                  label: section.schedule,
                  color: const Color(0xFF0369A1),
                ),
              if (section.status != null) IdeathonStatusPill(status: section.status!, compact: true),
              if (section.assignedCount > 0)
                EventMetaChip(
                  icon: AppIcons.ideas,
                  label: '${section.assignedCount} assigned',
                  color: const Color(0xFF4F46E5),
                ),
              if (section.pendingCount > 0)
                EventMetaChip(
                  icon: AppIcons.clock,
                  label: '${section.pendingCount} pending',
                  color: const Color(0xFFEA580C),
                ),
              if (section.evaluatedCount > 0)
                EventMetaChip(
                  icon: AppIcons.scoring,
                  label: '${section.evaluatedCount} evaluated',
                  color: const Color(0xFF059669),
                ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        decoration: kDashboardCardDecoration.copyWith(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: onToggle == null
            ? body
            : InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(14),
                child: body,
              ),
      ),
    );
  }
}
