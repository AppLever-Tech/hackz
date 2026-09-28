import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/utils/common_helpers.dart';

import '../models/export_request.dart';
import '../models/export_table.dart';

/// Presentation context for a generated PDF. Tenant identity comes from the
/// bound [HackzFirebase] workspace, not a `tenantId` field on business models.
class PdfExportContext {
  const PdfExportContext({
    required this.organisationName,
    required this.organisationCode,
    required this.documentTitle,
    required this.generatedAtLabel,
    this.eventName = '',
  });

  final String organisationName;
  final String organisationCode;
  final String documentTitle;
  final String generatedAtLabel;
  final String eventName;

  bool get hasEvent => eventName.trim().isNotEmpty;

  factory PdfExportContext.resolve({
    required ExportRequest request,
    required ExportTable table,
  }) {
    final String orgName = HackzFirebase.current.context.organisationName
        .trim();
    final String orgCode = HackzFirebase.current.context.organisationCode
        .trim();
    final String title = table.sheetName.trim().isEmpty
        ? request.module.displayName
        : table.sheetName.trim();
    return PdfExportContext(
      organisationName: orgName.isEmpty ? orgCode : orgName,
      organisationCode: orgCode,
      documentTitle: title,
      generatedAtLabel: formatDateTime(DateTime.now()),
      eventName: request.eventName.trim(),
    );
  }
}
