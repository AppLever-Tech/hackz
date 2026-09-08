import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/exports/event_certificates_export_provider.dart';
import 'package:hackz/features/events/models/event_report_item.dart';
import 'package:hackz/features/events/models/event_winner_entry.dart';
import 'package:hackz/features/events/widgets/event_reports_section.dart';
import 'package:hackz/features/exports/exports.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonReportsTab extends StatelessWidget {
  const IdeathonReportsTab({super.key, required this.vm, required this.actor});

  final IdeathonDetailsViewModel vm;
  final UserModel actor;

  @override
  Widget build(BuildContext context) {
    final bool usesWinners = vm.ideathon.eventKind.usesWinners;
    final List<EventCertificateRecipient> participants = _participants();
    final EventCertificateRecipient? winner = _recipientFromWinner(
      vm.workspace.winner,
      'Winner',
    );
    final EventCertificateRecipient? runnerUp = _recipientFromWinner(
      vm.workspace.runnerUp,
      'Runner-up',
    );
    final String eventDates = _eventDates();
    final String eventType = vm.ideathon.eventKind.label;

    return EventReportsSection(
      items: <EventReportItem>[
        _certificateItem(
          id: 'participation',
          title: 'Participation certificates',
          description:
              'Certificates for teams that participated in this event.',
          icon: AppIcons.ideas,
          module: ExportModule.participationCertificate,
          recipients: participants,
          eventType: eventType,
          eventDates: eventDates,
          unavailableReason:
              'Add participating ${vm.ideathon.eventKind.entriesLabel.toLowerCase()} before generating certificates.',
        ),
        if (usesWinners)
          _certificateItem(
            id: 'winner',
            title: 'Winner certificates',
            description:
                'Certificates for the official winner selected by Department Admin.',
            icon: AppIcons.achievement,
            module: ExportModule.winnerCertificate,
            recipients: <EventCertificateRecipient>[if (winner != null) winner],
            eventType: eventType,
            eventDates: eventDates,
            unavailableReason:
                'Winner certificates are available after Department Admin selects a winner.',
          ),
        if (usesWinners)
          _certificateItem(
            id: 'runnerUp',
            title: 'Runner-up certificates',
            description:
                'Certificates for the official runner-up selected by Department Admin.',
            icon: AppIcons.results,
            module: ExportModule.winnerCertificate,
            recipients: <EventCertificateRecipient>[
              if (runnerUp != null) runnerUp,
            ],
            eventType: eventType,
            eventDates: eventDates,
            unavailableReason:
                'Runner-up certificates are available after Department Admin selects a runner-up.',
          ),
      ],
    );
  }

  EventReportItem _certificateItem({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required ExportModule module,
    required List<EventCertificateRecipient> recipients,
    required String eventType,
    required String eventDates,
    required String unavailableReason,
  }) {
    final EventCertificatesExportProvider provider =
        EventCertificatesExportProvider(
          module: module,
          recipients: recipients,
          eventType: eventType,
          eventDates: eventDates,
        );
    final bool available = recipients.isNotEmpty && provider.canExport(actor);
    return EventReportItem(
      id: id,
      title: title,
      description: description,
      icon: icon,
      available: available,
      unavailableReason: unavailableReason,
      provider: provider,
      actionLabel: 'Generate Certificate',
      requestFor: (ExportFormat format) => ExportRequest(
        module: module,
        format: format,
        actor: actor,
        eventId: vm.ideathon.ideathonId,
        eventName: vm.ideathon.name,
      ),
    );
  }

  List<EventCertificateRecipient> _participants() {
    return vm.ideas
        .map(
          (IdeathonIdeaEntry entry) => EventCertificateRecipient(
            recipientName: _recipientName(
              teamName: entry.teamName,
              entryTitle: entry.ideaTitle,
              entryId: entry.ideaId,
            ),
            teamName: entry.teamName,
            entryTitle: entry.ideaTitle,
            entryId: entry.ideaId,
          ),
        )
        .where(
          (EventCertificateRecipient row) =>
              row.recipientName.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  EventCertificateRecipient? _recipientFromWinner(
    EventWinnerEntry? entry,
    String place,
  ) {
    if (entry == null) return null;
    final String recipient = _recipientName(
      teamName: entry.teamName,
      entryTitle: entry.ideaTitle,
      entryId: entry.ideaId,
    );
    if (recipient.isEmpty) return null;
    return EventCertificateRecipient(
      recipientName: recipient,
      teamName: entry.teamName,
      entryTitle: entry.ideaTitle,
      entryId: entry.ideaId,
      placeLabel: place,
    );
  }

  String _eventDates() {
    final String start = formatDayMonthYear(vm.ideathon.startDateTime);
    final String end = formatDayMonthYear(vm.ideathon.endDateTime);
    if (start == end) return start;
    return '$start – $end';
  }

  static String _recipientName({
    required String teamName,
    required String entryTitle,
    required String entryId,
  }) {
    final String team = teamName.trim();
    if (team.isNotEmpty) return team;
    final String title = entryTitle.trim();
    if (title.isNotEmpty) return title;
    return entryId.trim();
  }
}
