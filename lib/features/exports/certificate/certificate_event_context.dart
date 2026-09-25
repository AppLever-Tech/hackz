import '../../../utils/common_helpers.dart';
import '../../events/models/event_kind.dart';
import '../../events/models/event_winner_entry.dart';
import '../../ideathons/models/ideathon_idea_snapshot.dart';
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
    required this.organisationId,
    required this.participationEntries,
    this.winnerEntry,
    this.runnerUpEntry,
    this.thirdPlaceEntry,
  });

  final String eventId;
  final String eventName;
  final EventKind eventKind;
  final String eventDateLabel;
  final String organisationName;
  final String organisationId;
  final List<CertificateSelectableEntry> participationEntries;
  final CertificateSelectableEntry? winnerEntry;
  final CertificateSelectableEntry? runnerUpEntry;
  final CertificateSelectableEntry? thirdPlaceEntry;

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
      organisationId: vm.ideathon.orgId.trim(),
      participationEntries: participation,
      winnerEntry: _resolvePlacedEntry(
        workspaceEntry: vm.workspace.winner,
        selectedIdeaId: vm.ideathon.winnerIdeaId,
        ideas: vm.ideas,
        snapshots: vm.ideathon.ideas,
      ),
      runnerUpEntry: _resolvePlacedEntry(
        workspaceEntry: vm.workspace.runnerUp,
        selectedIdeaId: vm.ideathon.runnerUpIdeaId,
        ideas: vm.ideas,
        snapshots: vm.ideathon.ideas,
      ),
      thirdPlaceEntry: _resolvePlacedEntry(
        workspaceEntry: vm.workspace.thirdPlace,
        selectedIdeaId: vm.ideathon.thirdPlaceIdeaId,
        ideas: vm.ideas,
        snapshots: vm.ideathon.ideas,
      ),
    );
  }

  /// Event Details uses a lightweight workspace without winner rows; fall back to ideathon selection + ideas.
  static CertificateSelectableEntry? _resolvePlacedEntry({
    required EventWinnerEntry? workspaceEntry,
    required String selectedIdeaId,
    required List<IdeathonIdeaEntry> ideas,
    required List<IdeathonIdeaSnapshot> snapshots,
  }) {
    final CertificateSelectableEntry? fromWorkspace = _winnerEntry(workspaceEntry);
    if (fromWorkspace != null) return fromWorkspace;

    final String ideaId = selectedIdeaId.trim();
    if (ideaId.isEmpty) return null;

    for (final IdeathonIdeaEntry entry in ideas) {
      if (entry.ideaId.trim() != ideaId) continue;
      return CertificateSelectableEntry.fromIdeaEntry(entry);
    }

    for (final IdeathonIdeaSnapshot snapshot in snapshots) {
      if (snapshot.ideaId.trim() != ideaId) continue;
      final String team = snapshot.teamName.trim();
      final String title = snapshot.ideaTitle.trim();
      final String label = team.isNotEmpty ? team : (title.isNotEmpty ? title : ideaId);
      return CertificateSelectableEntry(
        entryId: ideaId,
        teamId: '',
        teamName: team,
        submissionTitle: title,
        displayLabel: label,
      );
    }

    return CertificateSelectableEntry(
      entryId: ideaId,
      teamId: '',
      teamName: '',
      submissionTitle: ideaId,
      displayLabel: ideaId,
    );
  }

  static CertificateSelectableEntry? _winnerEntry(EventWinnerEntry? entry) {
    if (entry == null) return null;
    return CertificateSelectableEntry.fromWinnerEntry(entry);
  }

}
