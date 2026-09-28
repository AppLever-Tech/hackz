class ExportColumn {
  const ExportColumn({required this.key, required this.header});

  final String key;
  final String header;
}

/// Normalized tabular payload shared by Excel and PDF renderers.
///
/// Cell values are [String] or [num]. Numbers stay numeric in Excel.
class ExportTable {
  const ExportTable({
    required this.sheetName,
    required this.columns,
    required this.rows,
  });

  final String sheetName;
  final List<ExportColumn> columns;
  final List<Map<String, Object?>> rows;

  bool get isEmpty => rows.isEmpty;
}
