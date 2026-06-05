class ImportExecutionResult {
  const ImportExecutionResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    this.failures = const <String>[],
  });

  final int imported;
  final int skipped;
  final int failed;
  final List<String> failures;

  int get totalProcessed => imported + skipped + failed;
}
