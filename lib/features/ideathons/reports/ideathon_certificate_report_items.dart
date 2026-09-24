import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/exports/event_certificates_export_provider.dart';
import 'package:hackz/features/events/models/event_report_item.dart';
import 'package:hackz/features/events/widgets/certificate_generation_dialog.dart';
import 'package:hackz/features/exports/certificate/certificate_event_context.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_config.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';
import 'package:hackz/features/exports/certificate/certificate_selectable_entry.dart';
import 'package:hackz/features/exports/certificate/certificate_team_member_loader.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';
import 'package:hackz/features/exports/models/export_format.dart';
import 'package:hackz/features/exports/models/export_module.dart';
import 'package:hackz/features/exports/models/export_request.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/user/models/user_model.dart';

/// Builds the three certificate download cards on the event Reports tab.
abstract final class IdeathonCertificateReportItems {
  IdeathonCertificateReportItems._();

  static Future<int> countParticipants(CertificateEventContext event) async {
    final Iterable<String> teamIds = event.participationEntries
        .map((CertificateSelectableEntry e) => e.teamId.trim())
        .where((String id) => id.isNotEmpty);
    if (teamIds.isEmpty) return 0;

    final Map<String, List<CertificateMember>> rosters =
        await CertificateTeamMemberLoader.membersByTeamId(teamIds);
    int total = 0;
    for (final CertificateSelectableEntry entry in event.participationEntries) {
      final List<CertificateMember> roster = rosters[entry.teamId.trim()] ?? const <CertificateMember>[];
      total += roster.isEmpty ? 1 : roster.length;
    }
    return total;
  }

  static List<EventReportItem> build({
    required IdeathonDetailsViewModel vm,
    required UserModel actor,
    required CertificateEventContext event,
    required int participantCount,
    CertificateEventSignatoryDraft? signatoryDraft,
    required bool signatoriesReady,
  }) {
    final List<EventCertificateSignatory> exportSignatories =
        CertificateEventSignatoryConfig.toExportSignatories(signatoryDraft);
    final String eventId = vm.ideathon.ideathonId.trim();
    final String eventName = vm.ideathon.name.trim();
    final int teamCount = event.participationEntries.length;
    final String entriesLabel = vm.ideathon.eventKind.entriesLabel;

    return <EventReportItem>[
      _participationCard(
        vm: vm,
        actor: actor,
        event: event,
        teamCount: teamCount,
        participantCount: participantCount,
        entriesLabel: entriesLabel,
        signatoryDraft: signatoryDraft,
        signatoriesReady: signatoriesReady,
      ),
      _winnerCard(
        vm: vm,
        actor: actor,
        event: event,
        eventId: eventId,
        eventName: eventName,
        signatoryDraft: signatoryDraft,
        signatoriesReady: signatoriesReady,
        exportSignatories: exportSignatories,
      ),
      _runnerUpCard(
        vm: vm,
        actor: actor,
        event: event,
        eventId: eventId,
        eventName: eventName,
        signatoryDraft: signatoryDraft,
        signatoriesReady: signatoriesReady,
        exportSignatories: exportSignatories,
      ),
    ];
  }

  static EventReportItem _participationCard({
    required IdeathonDetailsViewModel vm,
    required UserModel actor,
    required CertificateEventContext event,
    required int teamCount,
    required int participantCount,
    required String entriesLabel,
    required CertificateEventSignatoryDraft? signatoryDraft,
    required bool signatoriesReady,
  }) {
    final bool available = teamCount > 0;

    return EventReportItem(
      id: 'participation_certificate',
      title: 'Participation certificates',
      description:
          'Team certificates for participating ${entriesLabel.toLowerCase()} in ${vm.ideathon.eventKind.label}. Use Generate to choose recipients.',
      icon: AppIcons.submissions,
      available: available,
      unavailableReason: teamCount == 0
          ? 'Add participating ${entriesLabel.toLowerCase()} before generating certificates.'
          : '',
      metaPills: <EventReportMetaPill>[
        EventReportMetaPill(
          label: '$teamCount ${teamCount == 1 ? 'team' : 'teams'}',
          icon: AppIcons.teams,
          color: const Color(0xFF4338CA),
        ),
        EventReportMetaPill(
          label: '$participantCount ${participantCount == 1 ? 'participant' : 'participants'}',
          icon: AppIcons.teamMember,
          color: const Color(0xFF047857),
        ),
      ],
      generateLabel: 'Generate…',
      onGenerate: available && signatoriesReady
          ? (BuildContext context) => showCertificateGenerationDialog(
                context: context,
                event: event,
                actor: actor,
                certificateType: CertificateType.participation,
                signatoryDraft: signatoryDraft,
              )
          : null,
    );
  }

  static EventReportItem _winnerCard({
    required IdeathonDetailsViewModel vm,
    required UserModel actor,
    required CertificateEventContext event,
    required String eventId,
    required String eventName,
    required CertificateEventSignatoryDraft? signatoryDraft,
    required bool signatoriesReady,
    required List<EventCertificateSignatory> exportSignatories,
  }) {
    final CertificateSelectableEntry? winner = event.winnerEntry;
    final bool available = event.usesWinners && winner != null;
    final List<EventReportMetaPill> pills = winner == null
        ? const <EventReportMetaPill>[]
        : _teamAndIdeaPills(winner, accent: const Color(0xFFB45309));

    return EventReportItem(
      id: 'winner_certificate',
      title: 'Winner certificate',
      description: 'First-place certificate for the winning team.',
      icon: AppIcons.achievement,
      available: available,
      unavailableReason: !event.usesWinners
          ? 'This event type does not use winner certificates.'
          : 'Select a winner on the Winners tab before downloading.',
      metaPills: pills,
      provider: available
          ? EventCertificatesExportProvider(
              module: ExportModule.winnerCertificate,
              recipients: <EventCertificateRecipient>[
                _recipient(
                  winner,
                  CertificateType.winner,
                  placeLabel: 'First Place',
                  signatories: exportSignatories,
                ),
              ],
              eventType: event.eventTemplateLabel,
              eventDates: event.eventDateLabel,
              submissionLabel: event.submissionLabel,
            )
          : null,
      requestFor: available
          ? (ExportFormat format) => ExportRequest(
                module: ExportModule.winnerCertificate,
                format: format,
                actor: actor,
                eventId: eventId,
                eventName: eventName,
              )
          : null,
      actionLabel: 'Download certificate',
      generateLabel: 'Generate…',
      onGenerate: available && signatoriesReady
          ? (BuildContext context) => showCertificateGenerationDialog(
                context: context,
                event: event,
                actor: actor,
                certificateType: CertificateType.winner,
                signatoryDraft: signatoryDraft,
              )
          : null,
    );
  }

  static EventReportItem _runnerUpCard({
    required IdeathonDetailsViewModel vm,
    required UserModel actor,
    required CertificateEventContext event,
    required String eventId,
    required String eventName,
    required CertificateEventSignatoryDraft? signatoryDraft,
    required bool signatoriesReady,
    required List<EventCertificateSignatory> exportSignatories,
  }) {
    final CertificateSelectableEntry? runner = event.runnerUpEntry;
    final bool available = event.usesWinners && runner != null;
    final List<EventReportMetaPill> pills = runner == null
        ? const <EventReportMetaPill>[]
        : _teamAndIdeaPills(runner, accent: const Color(0xFF64748B));

    return EventReportItem(
      id: 'runner_up_certificate',
      title: 'Runner-up certificate',
      description: 'Second-place certificate for the runner-up team.',
      icon: AppIcons.starOutline,
      available: available,
      unavailableReason: !event.usesWinners
          ? 'This event type does not use runner-up certificates.'
          : 'Select a runner-up on the Winners tab before downloading.',
      metaPills: pills,
      provider: available
          ? EventCertificatesExportProvider(
              module: ExportModule.winnerCertificate,
              recipients: <EventCertificateRecipient>[
                _recipient(
                  runner,
                  CertificateType.runnerUp,
                  placeLabel: 'Runner-Up',
                  signatories: exportSignatories,
                ),
              ],
              eventType: event.eventTemplateLabel,
              eventDates: event.eventDateLabel,
              submissionLabel: event.submissionLabel,
            )
          : null,
      requestFor: available
          ? (ExportFormat format) => ExportRequest(
                module: ExportModule.winnerCertificate,
                format: format,
                actor: actor,
                eventId: eventId,
                eventName: eventName,
              )
          : null,
      actionLabel: 'Download certificate',
      generateLabel: 'Generate…',
      onGenerate: available && signatoriesReady
          ? (BuildContext context) => showCertificateGenerationDialog(
                context: context,
                event: event,
                actor: actor,
                certificateType: CertificateType.runnerUp,
                signatoryDraft: signatoryDraft,
              )
          : null,
    );
  }

  static List<EventReportMetaPill> _teamAndIdeaPills(
    CertificateSelectableEntry entry, {
    required Color accent,
  }) {
    final String team = entry.teamName.trim();
    final String idea = entry.submissionTitle.trim();
    final List<EventReportMetaPill> pills = <EventReportMetaPill>[];
    if (team.isNotEmpty) {
      pills.add(
        EventReportMetaPill(label: team, icon: AppIcons.teams, color: accent),
      );
    }
    if (idea.isNotEmpty) {
      pills.add(
        EventReportMetaPill(label: idea, icon: AppIcons.ideas, color: accent),
      );
    }
    return pills;
  }

  static EventCertificateRecipient _recipient(
    CertificateSelectableEntry entry,
    CertificateType type, {
    required String placeLabel,
    List<EventCertificateSignatory> signatories = const <EventCertificateSignatory>[],
  }) {
    final String team = entry.teamName.trim();
    final String title = entry.submissionTitle.trim();
    final String recipientName = team.isNotEmpty ? team : (title.isNotEmpty ? title : entry.displayLabel);
    return EventCertificateRecipient(
      recipientName: recipientName,
      entryId: entry.entryId,
      teamName: team,
      entryTitle: title,
      placeLabel: placeLabel,
      recipientType: CertificateRecipientType.team,
      certificateType: type,
      signatories: signatories,
    );
  }
}
