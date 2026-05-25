enum TeamStatus {
  active('active'),
  inactive('inactive'),
  locked('locked');

  const TeamStatus(this.value);
  final String value;

  static TeamStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'inactive':
        return TeamStatus.inactive;
      case 'locked':
        return TeamStatus.locked;
      case 'active':
      default:
        return TeamStatus.active;
    }
  }
}
