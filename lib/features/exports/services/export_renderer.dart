import '../models/export_format.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';

abstract class ExportRenderer {
  ExportFormat get format;

  Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
  });
}
