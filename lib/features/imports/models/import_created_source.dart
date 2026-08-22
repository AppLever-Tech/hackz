/// Audit source for records created via Hackz admin flows.
enum ImportCreatedSource {
  manual('MANUAL'),
  csvImport('CSV_IMPORT'),
  googleImport('GOOGLE_IMPORT');

  const ImportCreatedSource(this.value);
  final String value;
}
