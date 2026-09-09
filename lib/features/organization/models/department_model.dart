class DepartmentModel {
  const DepartmentModel({
    required this.name,
    required this.code,
    this.aliases = const <String>[],
  });

  final String name;
  final String code; // unique 3-4 letters department code
  /// Alternate names/codes used to resolve external CSV department values.
  final List<String> aliases;

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Trim, lowercase, and collapse repeated whitespace for department matching.
  static String normalizeKey(String raw) =>
      raw.trim().toLowerCase().replaceAll(_whitespace, ' ');

  static const List<DepartmentModel> master = <DepartmentModel>[
    DepartmentModel(name: 'Civil Engineering', code: 'CIV'),
    DepartmentModel(name: 'Computer Science and Engineering', code: 'CSE'),
    DepartmentModel(name: 'Electrical and Electronics Engineering', code: 'EEE'),
    DepartmentModel(name: 'Electronics and Communication Engineering', code: 'ECE'),
    DepartmentModel(name: 'Information Science and Engineering', code: 'ISE'),
    DepartmentModel(name: 'Mechanical Engineering', code: 'MECH'),
    DepartmentModel(name: 'Artificial Intelligence and Machine Learning', code: 'AIML'),
    DepartmentModel(name: 'Computer Science and Engineering (Data Science)', code: 'CSD'),
    DepartmentModel(name: 'Master of Business Administration', code: 'MBA'),
    DepartmentModel(name: 'Basic Sciences (Chem, Math, Phy)', code: 'BS'),
  ];

  static List<String> get masterNames => master.map((d) => d.name).toList(growable: false);

  static DepartmentModel? byName(String departmentName) {
    final normalized = normalizeKey(departmentName);
    if (normalized.isEmpty) return null;
    for (final d in master) {
      if (normalizeKey(d.name) == normalized) return d;
    }
    return null;
  }

  static DepartmentModel? byCode(String departmentCode) {
    final normalized = departmentCode.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final d in master) {
      if (d.code.toUpperCase() == normalized) return d;
    }
    return null;
  }

  static String resolveCode(String rawDepartment) {
    final raw = rawDepartment.trim();
    if (raw.isEmpty) return '';
    final byNameMatch = byName(raw);
    if (byNameMatch != null) return byNameMatch.code;
    final byCodeMatch = byCode(raw);
    if (byCodeMatch != null) return byCodeMatch.code;
    return raw.toUpperCase();
  }

  /// Suggests a department code from a display name (master list, else initials).
  static String suggestCode(String departmentName) {
    final masterMatch = byName(departmentName);
    if (masterMatch != null) return masterMatch.code;
    final words = departmentName
        .trim()
        .split(_whitespace)
        .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length > 1) {
      return words.map((word) => word[0]).join().toUpperCase();
    }
    final compact = departmentName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (compact.isEmpty) return '';
    return compact.length <= 6 ? compact : compact.substring(0, 6);
  }

  static String uniqueSuggestedCode(String departmentName, Set<String> existingCodes) {
    final String base = suggestCode(departmentName);
    if (base.isEmpty) return '';
    final Set<String> taken = existingCodes.map((String c) => c.trim().toUpperCase()).toSet();
    if (!taken.contains(base)) return base;
    for (var i = 2; i < 100; i++) {
      final String suffix = '$i';
      final String candidate =
          base.length + suffix.length <= 8 ? '$base$suffix' : '${base.substring(0, 8 - suffix.length)}$suffix';
      if (!taken.contains(candidate)) return candidate;
    }
    return base;
  }

  static List<String> parseAliases(Object? raw) {
    if (raw is! List) return const <String>[];
    return mergeAliases(const <String>[], raw.map((Object? item) => item?.toString() ?? ''));
  }

  static List<String> mergeAliases(Iterable<String> existing, Iterable<String> incoming) {
    final List<String> merged = <String>[];
    final Set<String> seen = <String>{};
    void add(String value) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final String key = normalizeKey(trimmed);
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      merged.add(trimmed);
    }

    for (final String value in existing) {
      add(value);
    }
    for (final String value in incoming) {
      add(value);
    }
    return List<String>.unmodifiable(merged);
  }

  static bool aliasMatchesDepartment({
    required String alias,
    required String name,
    required String code,
  }) {
    final String key = normalizeKey(alias);
    if (key.isEmpty) return true;
    return key == normalizeKey(name) || key == normalizeKey(code);
  }
}
