class FacultyProfile {
  const FacultyProfile({
    this.specialization = '',
    this.researchInterests = const <String>[],
  });

  final String specialization;
  final List<String> researchInterests;

  bool get isEmpty => specialization.trim().isEmpty && researchInterests.isEmpty;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (specialization.trim().isNotEmpty) map['specialization'] = specialization.trim();
    if (researchInterests.isNotEmpty) {
      map['researchInterests'] =
          researchInterests.map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList();
    }
    return map;
  }

  factory FacultyProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const FacultyProfile();
    final List<String> interests = <String>[];
    final dynamic raw = map['researchInterests'];
    if (raw is List) {
      for (final dynamic item in raw) {
        final String value = item.toString().trim();
        if (value.isNotEmpty) interests.add(value);
      }
    }
    return FacultyProfile(
      specialization: (map['specialization'] as String?) ?? '',
      researchInterests: interests,
    );
  }

  FacultyProfile copyWith({
    String? specialization,
    List<String>? researchInterests,
  }) {
    return FacultyProfile(
      specialization: specialization ?? this.specialization,
      researchInterests: researchInterests ?? this.researchInterests,
    );
  }
}
