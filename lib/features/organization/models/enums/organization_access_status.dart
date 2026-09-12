/// Organisation access status on Control Plane `hkzOrganizations`.
enum OrganizationAccessStatus {
  active,
  inactive;

  String get wireValue => name;

  String get label => this == OrganizationAccessStatus.active ? 'Active' : 'Inactive';

  static OrganizationAccessStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == OrganizationAccessStatus.inactive.wireValue) {
      return OrganizationAccessStatus.inactive;
    }
    return OrganizationAccessStatus.active;
  }
}
