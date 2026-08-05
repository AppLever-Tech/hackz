enum FeedbackStatus {
  open('OPEN'),
  inReview('IN_REVIEW'),
  completed('COMPLETED'),
  closed('CLOSED');

  const FeedbackStatus(this.value);
  final String value;

  String get label => switch (this) {
        FeedbackStatus.open => 'Open',
        FeedbackStatus.inReview => 'In Review',
        FeedbackStatus.completed => 'Completed',
        FeedbackStatus.closed => 'Closed',
      };

  static FeedbackStatus fromRaw(String raw) {
    final String n = raw.trim().toUpperCase().replaceAll(' ', '_');
    return switch (n) {
      'IN_REVIEW' => FeedbackStatus.inReview,
      'COMPLETED' => FeedbackStatus.completed,
      'CLOSED' => FeedbackStatus.closed,
      _ => FeedbackStatus.open,
    };
  }

  static const List<FeedbackStatus> lifecycle = <FeedbackStatus>[
    FeedbackStatus.open,
    FeedbackStatus.inReview,
    FeedbackStatus.completed,
    FeedbackStatus.closed,
  ];
}
