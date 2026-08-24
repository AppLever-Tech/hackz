import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_columns.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../models/event_winner_entry.dart';

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

    EventWinnerEntry? winner;
    EventWinnerEntry? runnerUp;
    for (final EventWinnerEntry entry in entries) {
      if (entry.rank == 1) winner = entry;
      if (entry.rank == 2) runnerUp = entry;
    }
    winner ??= entries.first;
    if (entries.length > 1) runnerUp ??= entries[1];

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        ResponsivePair(
          spacing: 12,
          first: _WinnerCard(
            entry: winner,
            placeLabel: 'Winner',
            icon: Icons.emoji_events_rounded,
            accent: const Color(0xFFC9A227),
            onOpenIdea: onOpenIdea,
            onOpenTeam: onOpenTeam,
            onOpenProblem: onOpenProblem,
          ),
          second: runnerUp == null
              ? const _EmptyPlaceCard(
                  placeLabel: 'Runner-up',
                  icon: Icons.military_tech_rounded,
                  accent: Color(0xFF8B9BB4),
                )
              : _WinnerCard(
                  entry: runnerUp,
                  placeLabel: 'Runner-up',
                  icon: Icons.military_tech_rounded,
                  accent: const Color(0xFF8B9BB4),
                  onOpenIdea: onOpenIdea,
                  onOpenTeam: onOpenTeam,
                  onOpenProblem: onOpenProblem,
                ),
        ),
      ],
    );
  }
}

class _EmptyPlaceCard extends StatelessWidget {
  const _EmptyPlaceCard({
    required this.placeLabel,
    required this.icon,
    required this.accent,
  });

  final String placeLabel;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 8),
              Text(
                placeLabel,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Not available yet.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.entry,
    required this.placeLabel,
    required this.icon,
    required this.accent,
    required this.onOpenIdea,
    required this.onOpenTeam,
    this.onOpenProblem,
  });

  final EventWinnerEntry entry;
  final String placeLabel;
  final IconData icon;
  final Color accent;
  final ValueChanged<EventWinnerEntry> onOpenIdea;
  final ValueChanged<EventWinnerEntry> onOpenTeam;
  final ValueChanged<EventWinnerEntry>? onOpenProblem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 22, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  placeLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accent),
                ),
              ),
              Text(
                'Score',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent.withValues(alpha: 0.9)),
              ),
              const SizedBox(width: 8),
              Text(
                entry.scoreLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  height: 1,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          if (entry.summary.trim().isNotEmpty)
            Text(
              entry.summary,
              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
            ),
        ],
      ),
    );
  }
}
