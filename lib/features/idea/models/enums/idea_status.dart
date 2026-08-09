enum IdeaStatus {
  draft('draft'),
  submitted('submitted'),
  underEvaluation('underEvaluation'),
  evaluated('evaluated'),
  ideathonAssigned('ideathonAssigned'),
  ideathonEvaluated('ideathonEvaluated'),
  prototypeSelected('prototypeSelected'),
  rejected('rejected'),
  winner('winner'),
  archived('archived');

  const IdeaStatus(this.value);
  final String value;

  /// Primary lifecycle stages shown in idea lifecycle UI (post-submission).
  static const List<IdeaStatus> lifecycleOrder = <IdeaStatus>[
    IdeaStatus.submitted,
    IdeaStatus.ideathonAssigned,
    IdeaStatus.ideathonEvaluated,
    IdeaStatus.prototypeSelected,
    IdeaStatus.winner,
  ];

  static IdeaStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (normalized) {
      'draft' => IdeaStatus.draft,
      'submitted' => IdeaStatus.submitted,
      'underevaluation' => IdeaStatus.underEvaluation,
      'evaluated' => IdeaStatus.evaluated,
      'ideathonassigned' => IdeaStatus.ideathonAssigned,
      'ideathonevaluated' => IdeaStatus.ideathonEvaluated,
      'prototypeselected' => IdeaStatus.prototypeSelected,
      'rejected' => IdeaStatus.rejected,
      'winner' => IdeaStatus.winner,
      'archived' => IdeaStatus.archived,
      _ => IdeaStatus.submitted,
    };
  }
}
