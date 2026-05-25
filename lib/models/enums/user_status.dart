enum UserStatus {
  pendingApproval('pendingApproval'),
  active('active'),
  rejected('rejected'),
  suspended('suspended');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'active':
        return UserStatus.active;
      case 'rejected':
        return UserStatus.rejected;
      case 'suspended':
        return UserStatus.suspended;
      case 'pendingapproval':
      default:
        return UserStatus.pendingApproval;
    }
  }
}
