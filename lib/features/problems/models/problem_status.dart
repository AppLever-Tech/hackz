/// Lifecycle status for a problem statement.
enum ProblemStatus {
  draft('draft'),
  active('active'),
  inactive('inactive'),
  archived('archived');

  const ProblemStatus(this.value);
  final String value;

  static ProblemStatus fromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'active':
        return ProblemStatus.active;
      case 'inactive':
        return ProblemStatus.inactive;
      case 'archived':
        return ProblemStatus.archived;
      case 'draft':
      default:
        return ProblemStatus.draft;
    }
  }

  static const List<ProblemStatus> lifecycleOrder = <ProblemStatus>[
    ProblemStatus.draft,
    ProblemStatus.active,
    ProblemStatus.inactive,
    ProblemStatus.archived,
  ];
}
