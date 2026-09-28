/// Ranked winner / runner-up row derived from existing evaluation results.
class EventWinnerEntry {
  const EventWinnerEntry({
    required this.rank,
    required this.placeLabel,
    required this.ideaId,
    required this.ideaTitle,
    required this.teamId,
    required this.teamName,
    required this.scoreLabel,
    this.summary = '',
    this.problemId = '',
    this.problemTitle = '',
  });

  final int rank;
  final String placeLabel;
  final String ideaId;
  final String ideaTitle;
  final String teamId;
  final String teamName;
  final String scoreLabel;
  final String summary;
  final String problemId;
  final String problemTitle;
}
