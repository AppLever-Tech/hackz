import '../../../utils/common_helpers.dart';
import '../../events/models/event_kind.dart';
import '../../events/models/event_winner_entry.dart';
import '../../ideathons/services/ideathon_details_loader.dart';
import 'certificate_selectable_entry.dart';

/// Event-scoped inputs for certificate UI (no Ideathon-specific rendering).
class CertificateEventContext {
  const CertificateEventContext({
    required this.eventId,
    required this.eventName,
    required this.eventKind,
    required this.eventDateLabel,
    required this.organisationName,
    required this.participationEntries,
    this.winnerEntry,
    this.runnerUpEntry,
  });

  final String eventId;
  final String eventName;
  final EventKind eventKind;
  final String eventDateLabel;
  final String organisationName;
  final List<CertificateSelectableEntry> participationEntries;
  final CertificateSelectableEntry? winnerEntry;
  final CertificateSelectableEntry? runnerUpEntry;

  bool get usesWinners => eventKind.usesWinners;

  String get submissionLabel => eventKind.payableItemLabel;

  String get eventTemplateLabel => eventKind.label;

  factory CertificateEventContext.fromIdeathonDetails(IdeathonDetailsViewModel vm) {
    final String start = formatDayMonthYear(vm.ideathon.startDateTime);
    final String end = formatDayMonthYear(vm.ideathon.endDateTime);
    final String dates = start == end ? start : '$start - $end';

    final List<CertificateSelectableEntry> participation = vm.ideas
        .map(CertificateSelectableEntry.fromIdeaEntry)
        .where((CertificateSelectableEntry e) => e.displayLabel.isNotEmpty)
        .toList(growable: false);

    return CertificateEventContext(
      eventId: vm.ideathon.ideathonId,
      eventName: vm.ideathon.name,
      eventKind: vm.ideathon.eventKind,
      eventDateLabel: dates,
      organisationName: vm.organisationName.trim().isEmpty
          ? vm.workspace.organisationName
          : vm.organisationName,
      participationEntries: participation,
      winnerEntry: _winnerEntry(vm.workspace.winner),
      runnerUpEntry: _winnerEntry(vm.workspace.runnerUp),
    );
  }

  static CertificateSelectableEntry? _winnerEntry(EventWinnerEntry? entry) {
    if (entry == null) return null;
    return CertificateSelectableEntry.fromWinnerEntry(entry);
  }

}
