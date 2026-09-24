import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/exports/certificate/certificate_event_context.dart';
import 'package:hackz/features/exports/certificate/certificate_generation_plan.dart';
import 'package:hackz/features/exports/certificate/certificate_generation_service.dart';
import 'package:hackz/features/exports/certificate/certificate_selectable_entry.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

void main() {
  CertificateEventContext context({required int entries, EventKind kind = EventKind.ideathon}) {
    return CertificateEventContext(
      eventId: 'evt-1',
      eventName: 'Demo Event',
      eventKind: kind,
      eventDateLabel: '01 Jan 2026',
      organisationName: 'Demo College',
      organisationId: 'org-demo',
      participationEntries: List<CertificateSelectableEntry>.generate(
        entries,
        (int i) => CertificateSelectableEntry(
          entryId: 'idea-$i',
          teamId: 'team-$i',
          teamName: 'Team $i',
          submissionTitle: 'Submission $i',
          displayLabel: 'Team $i',
        ),
      ),
    );
  }

  test('team participation uses combined PDF under threshold', () {
    final CertificateGenerationPlan plan = CertificateGenerationService.plan(
      event: context(entries: 10),
      certificateType: CertificateType.participation,
      recipientType: CertificateRecipientType.team,
      selectedEntries: context(entries: 10).participationEntries,
    );
    expect(plan.estimatedCertificates, 10);
    expect(plan.outputMode, CertificateOutputMode.multiPagePdf);
  });

  test('large participation switches to zip mode', () {
    final CertificateEventContext evt = context(entries: 40);
    final CertificateGenerationPlan plan = CertificateGenerationService.plan(
      event: evt,
      certificateType: CertificateType.participation,
      recipientType: CertificateRecipientType.team,
      selectedEntries: evt.participationEntries,
    );
    expect(plan.estimatedCertificates, 40);
    expect(plan.outputMode, CertificateOutputMode.zipArchive);
    expect(plan.isLargeJob, true);
  });

  test('hackathon uses prototype submission label from event kind', () {
    final CertificateEventContext evt = context(entries: 1, kind: EventKind.hackathon);
    expect(evt.submissionLabel, 'Prototype');
    expect(evt.eventTemplateLabel, 'Hackathon');
  });
}
