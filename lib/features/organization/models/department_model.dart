class DepartmentModel {
  const DepartmentModel({
    required this.name,
    required this.code,
  });

  final String name;
  final String code; // unique 3-4 letters department code

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
    final normalized = departmentName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final d in master) {
      if (d.name.toLowerCase() == normalized) return d;
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
}
