import '../../events/models/event_winner_entry.dart';
import '../../ideathons/services/ideathon_details_loader.dart';

/// One selectable submission row in the certificate UI.
class CertificateSelectableEntry {
  const CertificateSelectableEntry({
    required this.entryId,
    required this.teamId,
    required this.teamName,
    required this.submissionTitle,
    required this.displayLabel,
  });

  final String entryId;
  final String teamId;
  final String teamName;
  final String submissionTitle;
  final String displayLabel;

  factory CertificateSelectableEntry.fromIdeaEntry(IdeathonIdeaEntry entry) {
    final String team = entry.teamName.trim();
    final String title = entry.ideaTitle.trim();
    final String label = team.isNotEmpty
        ? team
        : (title.isNotEmpty ? title : entry.ideaId.trim());
    return CertificateSelectableEntry(
      entryId: entry.ideaId.trim(),
      teamId: entry.teamId.trim(),
      teamName: team,
      submissionTitle: title,
      displayLabel: label,
    );
  }

  factory CertificateSelectableEntry.fromWinnerEntry(EventWinnerEntry entry) {
    final String team = entry.teamName.trim();
    final String title = entry.ideaTitle.trim();
    final String label = team.isNotEmpty
        ? team
        : (title.isNotEmpty ? title : entry.ideaId.trim());
    return CertificateSelectableEntry(
      entryId: entry.ideaId.trim(),
      teamId: entry.teamId.trim(),
      teamName: team,
      submissionTitle: title,
      displayLabel: label,
    );
  }
}

/// Resolved team member for individual certificates.
class CertificateMember {
  const CertificateMember({
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;
}
