class CollegeAdminProfile {
  const CollegeAdminProfile({this.officeDesignation = ''});

  final String officeDesignation;

  bool get isEmpty => officeDesignation.trim().isEmpty;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (officeDesignation.trim().isNotEmpty) {
      map['officeDesignation'] = officeDesignation.trim();
    }
    return map;
  }

  factory CollegeAdminProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const CollegeAdminProfile();
    return CollegeAdminProfile(
      officeDesignation: (map['officeDesignation'] as String?) ?? '',
    );
  }

  CollegeAdminProfile copyWith({String? officeDesignation}) {
    return CollegeAdminProfile(
      officeDesignation: officeDesignation ?? this.officeDesignation,
    );
  }
}
