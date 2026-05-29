class DepartmentAdminProfile {
  const DepartmentAdminProfile({this.officeDesignation = ''});

  final String officeDesignation;

  bool get isEmpty => officeDesignation.trim().isEmpty;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (officeDesignation.trim().isNotEmpty) {
      map['officeDesignation'] = officeDesignation.trim();
    }
    return map;
  }

  factory DepartmentAdminProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const DepartmentAdminProfile();
    return DepartmentAdminProfile(
      officeDesignation: (map['officeDesignation'] as String?) ?? '',
    );
  }

  DepartmentAdminProfile copyWith({String? officeDesignation}) {
    return DepartmentAdminProfile(
      officeDesignation: officeDesignation ?? this.officeDesignation,
    );
  }
}
