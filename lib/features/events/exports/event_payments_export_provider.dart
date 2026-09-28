import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../payment/models/payment_model.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../models/event_payment_entry.dart';

/// Event-scoped payments already loaded on Event Details → Payments.
class EventPaymentsExportProvider implements ExportDataProvider {
  const EventPaymentsExportProvider({required this.entries});

  final List<EventPaymentEntry> entries;

  @override
  ExportModule get module => ExportModule.payments;

  @override
  List<ExportFormat> get supportedFormats => ExportFormat.reportFormats;

  @override
  bool get requiresEvent => true;

  @override
  bool canExport(UserModel actor) =>
      ExportTenantGuard.actorMatchesBoundOrganisation(actor);

  @override
  Future<ExportTable> load(ExportRequest request) async {
    if (!canExport(request.actor)) {
      throw ExportException.unauthorized();
    }
    if (!request.hasEventScope) {
      throw ExportException.missingEvent();
    }
    final String orgId = ExportTenantGuard.resolvedOrgId(request.actor);
    final String eventId = request.eventId.trim();
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final EventPaymentEntry entry in entries) {
      final PaymentModel? payment = entry.payment;
      if (payment != null) {
        if (orgId.isNotEmpty && payment.orgId.trim() != orgId) continue;
        if (!payment.belongsToEvent(eventId)) continue;
      }
      rows.add(<String, Object?>{
        'entry': entry.entryTitle.trim(),
        'team': entry.teamName.trim(),
        'payer': entry.payerName.trim(),
        'amount': payment?.amount,
        'status': _statusLabel(entry.status),
        'transactionId': (payment?.transactionId ?? '').trim(),
        'verifiedBy': (payment?.verifiedBy ?? '').trim(),
        'verifiedAt': payment?.verifiedAt == null
            ? ''
            : formatDateTime(payment!.verifiedAt!),
        'remarks': (payment?.remarks ?? '').trim(),
        'proof': entry.hasProof ? 'Yes' : 'No',
        'created': payment == null ? '' : formatDateTime(payment.createdAt),
      });
    }
    return ExportTable(
      sheetName: 'Payments',
      columns: const <ExportColumn>[
        ExportColumn(key: 'entry', header: 'Item'),
        ExportColumn(key: 'team', header: 'Team'),
        ExportColumn(key: 'payer', header: 'Paid by'),
        ExportColumn(key: 'amount', header: 'Amount'),
        ExportColumn(key: 'status', header: 'Status'),
        ExportColumn(key: 'transactionId', header: 'Transaction ID'),
        ExportColumn(key: 'verifiedBy', header: 'Validated by'),
        ExportColumn(key: 'verifiedAt', header: 'Validated on'),
        ExportColumn(key: 'remarks', header: 'Remarks'),
        ExportColumn(key: 'proof', header: 'Proof'),
        ExportColumn(key: 'created', header: 'Submitted'),
      ],
      rows: rows,
    );
  }

  /// Matches Event Payments workspace labels (not department Verified/Rejected).
  static String _statusLabel(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 'Confirmed',
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.rejected => 'Exception',
    };
  }
}
