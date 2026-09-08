import 'package:hackz/core/firebase/hackz_firebase.dart';

import '../../exports/models/export_exception.dart';
import '../../exports/models/export_format.dart';
import '../../exports/models/export_module.dart';
import '../../exports/models/export_request.dart';
import '../../exports/models/export_table.dart';
import '../../exports/services/export_data_provider.dart';
import '../../exports/services/export_file_namer.dart';
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
  });

  final String recipientName;
  final String teamName;
  final String entryTitle;
  final String entryId;
  final String placeLabel;
}

/// Event-generic participation / winner certificates. Excel is not supported.
class EventCertificatesExportProvider implements ExportDataProvider {
  const EventCertificatesExportProvider({
    required this.module,
    required this.recipients,
    this.eventType = '',
    this.eventDates = '',
  });

  @override
  final ExportModule module;
  final List<EventCertificateRecipient> recipients;
  final String eventType;
  final String eventDates;

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
    final String orgCode = _orgCode();
    final bool isAward = module == ExportModule.winnerCertificate;
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
    for (final EventCertificateRecipient recipient in recipients) {
      final String name = recipient.recipientName.trim();
      if (name.isEmpty) continue;
      final String place = recipient.placeLabel.trim();
      rows.add(<String, Object?>{
        'title': isAward
            ? 'Certificate of Achievement'
            : 'Certificate of Participation',
        'recipient': name,
        'team': recipient.teamName.trim(),
        'entry': recipient.entryTitle.trim(),
        'place': place,
        'achievement': isAward
            ? (place.isEmpty
                  ? 'is awarded recognition in the following event'
                  : 'is awarded the following recognition for')
            : 'has participated in the following event',
        'eventType': eventType.trim(),
        'eventDates': eventDates.trim(),
        'referenceId': _referenceId(
          orgCode: orgCode,
          eventId: request.eventId,
          entryId: recipient.entryId,
        ),
      });
    }
    return ExportTable(
      sheetName: module.displayName,
      columns: const <ExportColumn>[
        ExportColumn(key: 'recipient', header: 'Recipient'),
        ExportColumn(key: 'team', header: 'Team'),
        ExportColumn(key: 'entry', header: 'Entry'),
        ExportColumn(key: 'place', header: 'Recognition'),
        ExportColumn(key: 'referenceId', header: 'Reference'),
      ],
      rows: rows,
    );
  }

  static String _orgCode() {
    try {
      return HackzFirebase.current.context.organisationCode.trim();
    } catch (_) {
      return '';
    }
  }

  static String _referenceId({
    required String orgCode,
    required String eventId,
    required String entryId,
  }) {
    final List<String> parts = <String>[
      ExportFileNamer.sanitize(orgCode),
      ExportFileNamer.sanitize(eventId),
      ExportFileNamer.sanitize(entryId),
    ].where((String part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return '';
    final String joined = parts.join('-');
    return joined.length <= 48 ? joined : joined.substring(0, 48);
  }
}
