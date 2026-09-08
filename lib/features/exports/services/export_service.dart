import '../../../core/download/hackz_file_download.dart';
import '../models/export_exception.dart';
import '../models/export_format.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'excel_export_renderer.dart';
import 'export_data_provider.dart';
import 'export_file_namer.dart';
import 'export_renderer.dart';
import 'export_tenant_guard.dart';
import 'pdf_export_renderer.dart';

/// `Provider → normalized table → renderer → download`.
abstract final class ExportService {
  static const ExcelExportRenderer _excel = ExcelExportRenderer();
  static const PdfExportRenderer _pdf = PdfExportRenderer();

  static Future<HackzFileDownloadResult> export({
    required ExportRequest request,
    required ExportDataProvider provider,
  }) async {
    try {
      ExportTenantGuard.assertOrganisationWorkspace();
    } catch (_) {
      throw ExportException.tenantContext();
    }
    if (!provider.canExport(request.actor)) {
      throw ExportException.unauthorized();
    }
    if (request.module != provider.module) {
      throw ExportException.generationFailed(
        'Export module does not match the data provider.',
      );
    }
    if (!provider.supportedFormats.contains(request.format)) {
      throw ExportException.unsupportedFormat();
    }
    if (provider.requiresEvent && !request.hasEventScope) {
      throw ExportException.missingEvent();
    }

    final ExportTable table = await provider.load(request);
    if (table.isEmpty) {
      throw ExportException.noData();
    }

    final ExportRenderer renderer = _rendererFor(request.format);
    late final List<int> bytes;
    try {
      bytes = await renderer.render(table: table, request: request);
    } on ExportException {
      rethrow;
    } catch (error) {
      throw ExportException.generationFailed('$error');
    }
    return HackzFileDownload.save(
      fileName: ExportFileNamer.fileName(request: request, table: table),
      bytes: bytes,
      mimeType: request.format.mimeType,
    );
  }

  static ExportRenderer _rendererFor(ExportFormat format) {
    return switch (format) {
      ExportFormat.excel => _excel,
      ExportFormat.pdf => _pdf,
    };
  }
}
