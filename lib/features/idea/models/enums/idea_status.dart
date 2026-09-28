enum IdeaStatus {
  draft('draft'),
  submitted('submitted');

  const IdeaStatus(this.value);
  final String value;

  /// Primary lifecycle stages shown in idea lifecycle UI.
  static const List<IdeaStatus> lifecycleOrder = <IdeaStatus>[
    IdeaStatus.draft,
    IdeaStatus.submitted,
  ];

  static IdeaStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (normalized) {
      'draft' => IdeaStatus.draft,
      'submitted' => IdeaStatus.submitted,
      _ => IdeaStatus.submitted,
    };
  }
}
