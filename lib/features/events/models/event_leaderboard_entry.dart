/// Ranked idea/team row for the Event Leaderboard (graphic view).
///
/// Values come from existing evaluation/ranking results — no separate score.
class EventLeaderboardEntry {
  const EventLeaderboardEntry({
    required this.rank,
    required this.ideaId,
    required this.ideaTitle,
    required this.teamId,
    required this.teamName,
    this.overallScore,
    this.peakScore,
  });

  final int rank;
  final String ideaId;
  final String ideaTitle;
  final String teamId;
  final String teamName;

  /// Event overall score (existing aggregate average).
  final double? overallScore;

  /// Existing aggregate peak judge score, when present.
  final double? peakScore;

  String get overallScoreLabel =>
      overallScore == null ? '—' : overallScore!.toStringAsFixed(2);

  String get peakScoreLabel => peakScore == null ? '—' : peakScore!.toStringAsFixed(2);

  String get displayIdeaTitle {
    final String t = ideaTitle.trim();
    return t.isEmpty ? ideaId : t;
  }

  String get displayTeamName {
    final String t = teamName.trim();
    return t.isEmpty ? 'Team' : t;
  }
}

/// Highlight picks from already-ranked event evaluation rows.
abstract final class EventLeaderboardHighlights {
  EventLeaderboardHighlights._();

  static EventLeaderboardEntry? highestEvaluated(List<EventLeaderboardEntry> ranked) {
    EventLeaderboardEntry? best;
    for (final EventLeaderboardEntry e in ranked) {
      if (e.overallScore == null) continue;
      if (best == null || e.overallScore! > (best.overallScore ?? double.negativeInfinity)) {
        best = e;
      }
    }
    return best;
  }

  /// Peak existing judge score among ranked rows (not a separate innovation engine).
  static EventLeaderboardEntry? mostInnovative(List<EventLeaderboardEntry> ranked) {
    EventLeaderboardEntry? best;
    for (final EventLeaderboardEntry e in ranked) {
      if (e.peakScore == null) continue;
      if (best == null || e.peakScore! > (best.peakScore ?? double.negativeInfinity)) {
        best = e;
      }
    }
    return best;
  }
}
