enum ExportFormat {
  excel,
  pdf;

  String get fileExtension => switch (this) {
        ExportFormat.excel => 'xlsx',
        ExportFormat.pdf => 'pdf',
      };

  String get mimeType => switch (this) {
        ExportFormat.excel =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ExportFormat.pdf => 'application/pdf',
      };

  String get label => switch (this) {
        ExportFormat.excel => 'Excel',
        ExportFormat.pdf => 'PDF',
      };
}
