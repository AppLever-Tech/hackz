class ExportColumn {
  const ExportColumn({required this.key, required this.header});

  final String key;
  final String header;
}

/// Normalized tabular payload shared by Excel and future PDF renderers.
class ExportTable {
  const ExportTable({
    required this.sheetName,
    required this.columns,
    required this.rows,
  });

  final String sheetName;
  final List<ExportColumn> columns;
  final List<Map<String, String>> rows;

  bool get isEmpty => rows.isEmpty;
}
