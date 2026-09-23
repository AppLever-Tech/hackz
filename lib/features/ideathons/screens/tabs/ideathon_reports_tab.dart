import 'package:flutter/material.dart';
import 'package:hackz/features/events/widgets/event_reports_section.dart';
import 'package:hackz/features/exports/certificate/certificate_event_context.dart';
import 'package:hackz/features/ideathons/reports/ideathon_certificate_report_items.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

class IdeathonReportsTab extends StatelessWidget {
  const IdeathonReportsTab({super.key, required this.vm, required this.actor});

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    final CertificateEventContext eventContext = CertificateEventContext.fromIdeathonDetails(vm);

    return FutureBuilder<int>(
      future: IdeathonCertificateReportItems.countParticipants(eventContext),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int participantCount = snapshot.data ?? 0;
        final items = IdeathonCertificateReportItems.build(
          vm: vm,
          actor: actor,
          event: eventContext,
          participantCount: participantCount,
        );

        return EventReportsSection(
          intro:
              'Download participation, winner, and runner-up certificate PDFs. Participation downloads include every participating team in one file.',
          items: items,
        );
      },
    );
  }
}
