class ImportExecutionResult {
  const ImportExecutionResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    this.failures = const <String>[],
    this.usersImported = 0,
    this.teamsImported = 0,
    this.departmentsResolved = 0,
    this.departmentsCreated = 0,
  });

  final int imported;
  final int skipped;
  final int failed;
  final List<String> failures;
  final int usersImported;
  final int teamsImported;
  final int departmentsResolved;
  final int departmentsCreated;

  int get totalProcessed => imported + skipped + failed;

  ImportExecutionResult copyWith({
    int? imported,
    int? skipped,
    int? failed,
    List<String>? failures,
    int? usersImported,
    int? teamsImported,
    int? departmentsResolved,
    int? departmentsCreated,
  }) {
    return ImportExecutionResult(
      imported: imported ?? this.imported,
      skipped: skipped ?? this.skipped,
      failed: failed ?? this.failed,
      failures: failures ?? this.failures,
      usersImported: usersImported ?? this.usersImported,
      teamsImported: teamsImported ?? this.teamsImported,
      departmentsResolved: departmentsResolved ?? this.departmentsResolved,
      departmentsCreated: departmentsCreated ?? this.departmentsCreated,
    );
  }
}
