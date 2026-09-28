class TeamMemberProfile {
  const TeamMemberProfile({
    this.program = '',
    this.yearOfStudy = '',
    this.skills = const <String>[],
  });

  final String program;
  final String yearOfStudy;
  final List<String> skills;

  bool get isEmpty => program.trim().isEmpty && yearOfStudy.trim().isEmpty && skills.isEmpty;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (program.trim().isNotEmpty) map['program'] = program.trim();
    if (yearOfStudy.trim().isNotEmpty) map['yearOfStudy'] = yearOfStudy.trim();
    if (skills.isNotEmpty) {
      map['skills'] = skills.map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList();
    }
    return map;
  }

  factory TeamMemberProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const TeamMemberProfile();
    final List<String> parsed = <String>[];
    final dynamic raw = map['skills'];
    if (raw is List) {
      for (final dynamic item in raw) {
        final String value = item.toString().trim();
        if (value.isNotEmpty) parsed.add(value);
      }
    }
    return TeamMemberProfile(
      program: (map['program'] as String?) ?? '',
      yearOfStudy: (map['yearOfStudy'] as String?) ?? '',
      skills: parsed,
    );
  }

  TeamMemberProfile copyWith({
    String? program,
    String? yearOfStudy,
    List<String>? skills,
  }) {
    return TeamMemberProfile(
      program: program ?? this.program,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      skills: skills ?? this.skills,
    );
  }
}
