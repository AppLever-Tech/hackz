import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../events/models/event_leaderboard_entry.dart';

/// Premium Top 3 podium: 2–1–3 on desktop, stacked 1 → 2 → 3 on mobile.
class PodiumWidget extends StatelessWidget {
  const PodiumWidget({
    super.key,
    required this.rows,
    this.onOpenIdea,
    this.onOpenTeam,
  });

  /// Ranked entries (1st, 2nd, 3rd). Caller passes a sorted slice.
  final List<EventLeaderboardEntry> rows;
  final ValueChanged<EventLeaderboardEntry>? onOpenIdea;
  final ValueChanged<EventLeaderboardEntry>? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final EventLeaderboardEntry? first = rows.isNotEmpty ? rows.first : null;
    final EventLeaderboardEntry? second = rows.length > 1 ? rows[1] : null;
    final EventLeaderboardEntry? third = rows.length > 2 ? rows[2] : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < ResponsiveBreakpoints.mobile;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PodiumSlot(
                place: 1,
                entry: first,
                prominence: 1,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
              const SizedBox(height: 10),
              _PodiumSlot(
                place: 2,
                entry: second,
                prominence: 0.92,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
              const SizedBox(height: 10),
              _PodiumSlot(
                place: 3,
                entry: third,
                prominence: 0.88,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: _PodiumSlot(
                place: 2,
                entry: second,
                prominence: 0.78,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PodiumSlot(
                place: 1,
                entry: first,
                prominence: 1,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PodiumSlot(
                place: 3,
                entry: third,
                prominence: 0.7,
                onOpenIdea: onOpenIdea,
                onOpenTeam: onOpenTeam,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.place,
    required this.entry,
    required this.prominence,
    this.onOpenIdea,
    this.onOpenTeam,
  });

  final int place;
  final EventLeaderboardEntry? entry;
  final double prominence;
  final ValueChanged<EventLeaderboardEntry>? onOpenIdea;
  final ValueChanged<EventLeaderboardEntry>? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final String medal = switch (place) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };
    final String placeLabel = switch (place) {
      1 => '1st',
      2 => '2nd',
      _ => '3rd',
    };
    final List<Color> gradient = switch (place) {
      1 => const <Color>[Color(0xFF7C3AED), Color(0xFFA855F7)],
      2 => const <Color>[Color(0xFF2563EB), Color(0xFF38BDF8)],
      _ => const <Color>[Color(0xFFEA580C), Color(0xFFF97316)],
    };
    final double minHeight = 132 * prominence;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$medal $placeLabel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: place == 1 ? 20 : 16,
            fontWeight: FontWeight.w900,
            color: gradient.first,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: entry == null
                ? const Center(
                    child: Text(
                      '—',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      ContextPill(
                        label: entry!.displayIdeaTitle,
                        semantic: ContextPillSemantic.idea,
                        onTap: () => onOpenIdea?.call(entry!),
                        enabled: onOpenIdea != null,
                        compact: true,
                        fitContent: true,
                      ),
                      const SizedBox(height: 6),
                      ContextPill(
                        label: entry!.displayTeamName,
                        semantic: ContextPillSemantic.team,
                        onTap: () => onOpenTeam?.call(entry!),
                        enabled: onOpenTeam != null && entry!.teamId.trim().isNotEmpty,
                        compact: true,
                        fitContent: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry!.overallScoreLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Text(
                        'Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
