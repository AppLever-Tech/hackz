enum FeedbackType {
  issue('ISSUE'),
  enhancement('ENHANCEMENT');

  const FeedbackType(this.value);
  final String value;

  String get label => switch (this) {
        FeedbackType.issue => 'Issue',
        FeedbackType.enhancement => 'Enhancement',
      };

  static FeedbackType fromRaw(String raw) {
    final String n = raw.trim().toUpperCase();
    return switch (n) {
      'ENHANCEMENT' => FeedbackType.enhancement,
      _ => FeedbackType.issue,
    };
  }
}
