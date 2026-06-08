enum IdeathonStatus {
  draft('draft'),
  scheduled('scheduled'),
  inProgress('inProgress'),
  completed('completed'),
  archived('archived');

  const IdeathonStatus(this.value);
  final String value;

  static const List<IdeathonStatus> lifecycleOrder = <IdeathonStatus>[
    IdeathonStatus.draft,
    IdeathonStatus.scheduled,
    IdeathonStatus.inProgress,
    IdeathonStatus.completed,
    IdeathonStatus.archived,
  ];

  static IdeathonStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (normalized) {
      'draft' => IdeathonStatus.draft,
      'scheduled' => IdeathonStatus.scheduled,
      'inprogress' => IdeathonStatus.inProgress,
      'completed' => IdeathonStatus.completed,
      'archived' => IdeathonStatus.archived,
      _ => IdeathonStatus.draft,
    };
  }
}
