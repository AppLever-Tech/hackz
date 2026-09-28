class ProfessionalProfile {
  const ProfessionalProfile({
    this.company = '',
    this.designation = '',
    this.yearsOfExperience = 0,
    this.expertiseAreas = const <String>[],
  });

  final String company;
  final String designation;
  final int yearsOfExperience;
  final List<String> expertiseAreas;

  bool get isEmpty =>
      company.trim().isEmpty &&
      designation.trim().isEmpty &&
      yearsOfExperience <= 0 &&
      expertiseAreas.isEmpty;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (company.trim().isNotEmpty) map['company'] = company.trim();
    if (designation.trim().isNotEmpty) map['designation'] = designation.trim();
    if (yearsOfExperience > 0) map['yearsOfExperience'] = yearsOfExperience;
    if (expertiseAreas.isNotEmpty) {
      map['expertiseAreas'] = expertiseAreas.map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList();
    }
    return map;
  }

  factory ProfessionalProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const ProfessionalProfile();
    final List<String> areas = <String>[];
    final dynamic rawAreas = map['expertiseAreas'];
    if (rawAreas is List) {
      for (final dynamic item in rawAreas) {
        final String value = item.toString().trim();
        if (value.isNotEmpty) areas.add(value);
      }
    }
    return ProfessionalProfile(
      company: (map['company'] as String?) ?? '',
      designation: (map['designation'] as String?) ?? '',
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toInt() ?? 0,
      expertiseAreas: areas,
    );
  }

  ProfessionalProfile copyWith({
    String? company,
    String? designation,
    int? yearsOfExperience,
    List<String>? expertiseAreas,
  }) {
    return ProfessionalProfile(
      company: company ?? this.company,
      designation: designation ?? this.designation,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      expertiseAreas: expertiseAreas ?? this.expertiseAreas,
    );
  }
}
