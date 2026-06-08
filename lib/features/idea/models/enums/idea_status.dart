enum IdeaStatus {
  draft('draft'),
  submitted('submitted'),
  underEvaluation('underEvaluation'),
  evaluated('evaluated'),
  shortlisted('shortlisted'),
  rejected('rejected'),
  eventAssigned('eventAssigned'),
  winner('winner'),
  archived('archived');

  const IdeaStatus(this.value);
  final String value;

  /// Primary lifecycle stages shown in idea lifecycle UI (post-submission).
  static const List<IdeaStatus> lifecycleOrder = <IdeaStatus>[
    IdeaStatus.submitted,
    IdeaStatus.underEvaluation,
    IdeaStatus.evaluated,
    IdeaStatus.shortlisted,
    IdeaStatus.eventAssigned,
    IdeaStatus.winner,
  ];

  static IdeaStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    switch (normalized) {
      case 'draft':
      case 'pendingsubmission':
        return IdeaStatus.draft;
      case 'submitted':
        return IdeaStatus.submitted;
      case 'underevaluation':
      case 'underreview':
        return IdeaStatus.underEvaluation;
      case 'evaluated':
        return IdeaStatus.evaluated;
      case 'shortlisted':
      case 'approved':
        return IdeaStatus.shortlisted;
      case 'rejected':
        return IdeaStatus.rejected;
      case 'eventassigned':
        return IdeaStatus.eventAssigned;
      case 'winner':
        return IdeaStatus.winner;
      case 'archived':
        return IdeaStatus.archived;
      default:
        return IdeaStatus.submitted;
    }
  }
}
