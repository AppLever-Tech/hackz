enum UserStatus {
  pending('pending'),
  active('active'),
  rejected('rejected');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'active':
        return UserStatus.active;
      case 'rejected':
        return UserStatus.rejected;
      case 'pending':
      default:
        return UserStatus.pending;
    }
  }
}
