import '../models/export_format.dart';
import '../models/export_module.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';

/// `Hackz_<Event>_<Report>_<yyyyMMdd>.xlsx` — event segment omitted when unused.
/// Certificates append the recipient when the file contains a single page.
abstract final class ExportFileNamer {
  static String fileName({
    required ExportRequest request,
    ExportTable? table,
    ExportFormat? format,
  }) {
    final ExportFormat resolved = format ?? request.format;
    final List<String> parts = <String>['Hackz'];
    final String event = sanitize(request.eventName);
    if (event.isNotEmpty) parts.add(event);
    parts.add(request.module.fileToken);
    final String subject = _certificateSubject(request, table);
    if (subject.isNotEmpty) parts.add(subject);
    parts.add(_dateStamp(DateTime.now()));
    return '${parts.join('_')}.${resolved.fileExtension}';
  }

  static String sanitize(String raw) {
    final String collapsed = raw
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (collapsed.isEmpty) return '';
    return collapsed.length <= 40 ? collapsed : collapsed.substring(0, 40);
  }

  static String _certificateSubject(ExportRequest request, ExportTable? table) {
    if (request.module.documentKind != ExportDocumentKind.certificate) {
      return '';
    }
    if (table == null || table.rows.length != 1) return '';
    final Object? name = table.rows.first['recipient'];
    if (name is! String) return '';
    return sanitize(name);
  }

  static String _dateStamp(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
