import 'certificate_data.dart';
import 'certificate_event_context.dart';
import 'certificate_selectable_entry.dart';
import 'certificate_type.dart';

/// Builds normalized [CertificateData] for the Sample A renderer.
abstract final class CertificateDataFactory {
  CertificateDataFactory._();

  static CertificateData build({
    required CertificateEventContext event,
    required CertificateType certificateType,
    required CertificateRecipientType recipientType,
    required String recipientName,
    required CertificateSelectableEntry entry,
    List<CertificateSignatory> signatories = const <CertificateSignatory>[],
  }) {
    return CertificateData(
      certificateType: certificateType,
      recipientType: recipientType,
      recipientName: recipientName.trim(),
      teamName: entry.teamName.trim(),
      organisationName: event.organisationName.trim(),
      eventName: event.eventName.trim(),
      eventTemplateLabel: event.eventTemplateLabel,
      eventDateLabel: event.eventDateLabel,
      submissionTitle: entry.submissionTitle.trim(),
      submissionLabel: event.submissionLabel,
      achievementLabel: _achievementLabel(certificateType),
      signatories: signatories,
    );
  }

  static String _achievementLabel(CertificateType type) => switch (type) {
        CertificateType.participation => '',
        CertificateType.winner => 'First Place',
        CertificateType.runnerUp => 'Second Place',
      };
}
