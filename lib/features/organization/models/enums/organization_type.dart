enum OrganizationType {
  college(1, 'College'),
  company(2, 'Company'),
  researchInstitute(3, 'Research Institute'),
  trainingCenter(4, 'Training Center');

  const OrganizationType(this.value, this.displayName);

  final int value;
  final String displayName;

  static OrganizationType? fromValue(int? value) {
    if (value == null) return null;
    for (final type in OrganizationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  static OrganizationType? fromFirestoreValue(dynamic value) {
    if (value is int) return fromValue(value);
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      switch (normalized) {
        case 'college':
          return OrganizationType.college;
        case 'company':
          return OrganizationType.company;
        case 'research institute':
          return OrganizationType.researchInstitute;
        case 'training center':
          return OrganizationType.trainingCenter;
        default:
          return null;
      }
    }
    return null;
  }

  static String displayLabelOf(OrganizationType? type) {
    return type?.displayName ?? 'Not Specified';
  }
}
