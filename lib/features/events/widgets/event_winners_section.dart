import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../models/event_winner_entry.dart';
import 'event_detail_section.dart';

/// Ranked winners presentation reused by Ideathon and future Hackathon.
class EventWinnersSection extends StatelessWidget {
  const EventWinnersSection({
    super.key,
    required this.entries,
    required this.onOpenIdea,
    required this.onOpenTeam,
    this.emptyMessage = 'Winners appear after evaluation results are available.',
    this.onOpenProblem,
  });

  final List<EventWinnerEntry> entries;
  final ValueChanged<EventWinnerEntry> onOpenIdea;
  final ValueChanged<EventWinnerEntry> onOpenTeam;
  final ValueChanged<EventWinnerEntry>? onOpenProblem;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final EventWinnerEntry entry = entries[index];
        return EventDetailSection(
          title: entry.placeLabel,
          icon: index == 0 ? AppIcons.achievement : AppIcons.results,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ContextPill(
                    label: entry.ideaTitle,
                    semantic: ContextPillSemantic.idea,
                    onTap: () => onOpenIdea(entry),
                    compact: true,
                    fitContent: true,
                  ),
                  if (entry.teamName.trim().isNotEmpty)
                    ContextPill(
                      label: entry.teamName,
                      semantic: ContextPillSemantic.team,
                      onTap: () => onOpenTeam(entry),
                      enabled: entry.teamId.trim().isNotEmpty,
                      compact: true,
                      fitContent: true,
                    ),
                  if (entry.problemTitle.trim().isNotEmpty)
                    ContextPill(
                      label: entry.problemTitle,
                      semantic: ContextPillSemantic.problem,
                      onTap: () => onOpenProblem?.call(entry),
                      enabled: onOpenProblem != null && entry.problemId.trim().isNotEmpty,
                      compact: true,
                      fitContent: true,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Score  ${entry.scoreLabel}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              if (entry.summary.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  entry.summary,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
