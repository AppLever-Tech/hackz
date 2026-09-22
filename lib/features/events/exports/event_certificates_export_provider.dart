import 'package:hackz/features/exports/certificate/certificate_type.dart';

import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_tenant_guard.dart';
import '../../user/models/user_model.dart';

/// One certificate recipient mapped from existing event workspace data.
class EventCertificateRecipient {
  const EventCertificateRecipient({
    required this.recipientName,
    required this.entryId,
    this.teamName = '',
    this.entryTitle = '',
    this.placeLabel = '',
    this.recipientType = CertificateRecipientType.team,
    this.certificateType,
    this.signatories = const <EventCertificateSignatory>[],
  });

  final String recipientName;
  final String teamName;
  final String entryTitle;
  final String entryId;
  final String placeLabel;
  final CertificateRecipientType recipientType;
  final CertificateType? certificateType;
  final List<EventCertificateSignatory> signatories;
}

class EventCertificateSignatory {
  const EventCertificateSignatory({
    this.name = '',
    this.designation = '',
    this.signatureBytes,
  });

  final String name;
  final String designation;
  final List<int>? signatureBytes;
}

/// Event-generic participation / winner certificates. Excel is not supported.
class EventCertificatesExportProvider implements ExportDataProvider {
  const EventCertificatesExportProvider({
    required this.module,
    required this.recipients,
    this.eventType = '',
    this.eventDates = '',
    this.submissionLabel = '',
  });

  @override
  final ExportModule module;
  final List<EventCertificateRecipient> recipients;
  final String eventType;
  final String eventDates;
  final String submissionLabel;

  @override
  List<ExportFormat> get supportedFormats => ExportFormat.certificateFormats;

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
    if (module.documentKind != ExportDocumentKind.certificate) {
      throw ExportException.generationFailed(
        'Certificate provider received a report module.',
      );
    }
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final EventCertificateRecipient recipient in recipients) {
      final String name = recipient.recipientName.trim();
      if (name.isEmpty) continue;
      final CertificateType type = recipient.certificateType ??
          _defaultType(module: module, placeLabel: recipient.placeLabel);
      rows.add(<String, Object?>{
        'certificateType': type.wireValue,
        'recipientType': recipient.recipientType.wireValue,
        'recipient': name,
        'team': recipient.teamName.trim(),
        'entry': recipient.entryTitle.trim(),
        'submissionLabel': submissionLabel.trim(),
        'place': recipient.placeLabel.trim(),
        'achievementLabel': _achievementLabel(type),
        'eventType': eventType.trim(),
        'eventDates': eventDates.trim(),
        ..._signatoryFields(recipient.signatories),
      });
    }
    return ExportTable(
      sheetName: module.displayName,
      columns: const <ExportColumn>[
        ExportColumn(key: 'recipient', header: 'Recipient'),
        ExportColumn(key: 'team', header: 'Team'),
        ExportColumn(key: 'entry', header: 'Entry'),
        ExportColumn(key: 'certificateType', header: 'Type'),
      ],
      rows: rows,
    );
  }

  static CertificateType _defaultType({
    required ExportModule module,
    required String placeLabel,
  }) {
    if (module == ExportModule.participationCertificate) {
      return CertificateType.participation;
    }
    final String place = placeLabel.trim().toLowerCase();
    if (place.contains('runner')) return CertificateType.runnerUp;
    return CertificateType.winner;
  }

  static String _achievementLabel(CertificateType type) => switch (type) {
        CertificateType.participation => '',
        CertificateType.winner => 'First Place',
        CertificateType.runnerUp => 'Second Place',
      };

  static Map<String, Object?> _signatoryFields(List<EventCertificateSignatory> signatories) {
    final Map<String, Object?> fields = <String, Object?>{};
    for (int i = 0; i < signatories.length && i < 2; i++) {
      final EventCertificateSignatory s = signatories[i];
      final int n = i + 1;
      fields['signatory${n}Name'] = s.name.trim();
      fields['signatory${n}Designation'] = s.designation.trim();
      if (s.signatureBytes != null && s.signatureBytes!.isNotEmpty) {
        fields['signatory${n}SignatureBytes'] = s.signatureBytes;
      }
    }
    return fields;
  }
}
