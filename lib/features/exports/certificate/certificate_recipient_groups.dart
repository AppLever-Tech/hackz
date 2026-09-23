import 'certificate_selectable_entry.dart';

/// Stable id for team + submission selection.
String certificateTeamSubmissionKey(CertificateSelectableEntry entry) => entry.entryId.trim();

/// Stable id for individual + team + submission.
String certificateIndividualSubmissionKey({
  required String userId,
  required CertificateSelectableEntry entry,
}) => '${userId.trim()}|${entry.entryId.trim()}';

class CertificateTeamSubmissionGroup {
  const CertificateTeamSubmissionGroup({
    required this.teamKey,
    required this.teamName,
    required this.submissions,
  });

  final String teamKey;
  final String teamName;
  final List<CertificateSelectableEntry> submissions;
}

abstract final class CertificateRecipientGroups {
  CertificateRecipientGroups._();

  static String teamKeyFor(CertificateSelectableEntry entry) {
    final String teamId = entry.teamId.trim();
    if (teamId.isNotEmpty) return teamId;
    final String teamName = entry.teamName.trim();
    if (teamName.isNotEmpty) return teamName.toLowerCase();
    return entry.entryId.trim();
  }

  static List<CertificateTeamSubmissionGroup> groupByTeam(List<CertificateSelectableEntry> entries) {
    final Map<String, CertificateTeamSubmissionGroup> byKey = <String, CertificateTeamSubmissionGroup>{};
    for (final CertificateSelectableEntry entry in entries) {
      final String key = teamKeyFor(entry);
      final CertificateTeamSubmissionGroup? existing = byKey[key];
      if (existing == null) {
        byKey[key] = CertificateTeamSubmissionGroup(
          teamKey: key,
          teamName: _displayTeamName(entry),
          submissions: <CertificateSelectableEntry>[entry],
        );
      } else {
        final List<CertificateSelectableEntry> next = List<CertificateSelectableEntry>.from(existing.submissions)
          ..add(entry);
        byKey[key] = CertificateTeamSubmissionGroup(
          teamKey: existing.teamKey,
          teamName: existing.teamName,
          submissions: next,
        );
      }
    }
    final List<CertificateTeamSubmissionGroup> groups = <CertificateTeamSubmissionGroup>[];
    for (final CertificateTeamSubmissionGroup group in byKey.values) {
      final List<CertificateSelectableEntry> sorted = List<CertificateSelectableEntry>.from(group.submissions)
        ..sort(
          (CertificateSelectableEntry a, CertificateSelectableEntry b) =>
              a.submissionTitle.toLowerCase().compareTo(b.submissionTitle.toLowerCase()),
        );
      groups.add(
        CertificateTeamSubmissionGroup(
          teamKey: group.teamKey,
          teamName: group.teamName,
          submissions: sorted,
        ),
      );
    }
    groups.sort((CertificateTeamSubmissionGroup a, CertificateTeamSubmissionGroup b) =>
        a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase()));
    return groups;
  }

  static String _displayTeamName(CertificateSelectableEntry entry) {
    final String team = entry.teamName.trim();
    if (team.isNotEmpty) return team;
    return entry.displayLabel.trim().isEmpty ? 'Team' : entry.displayLabel.trim();
  }

  static bool matchesTeamSearch(CertificateTeamSubmissionGroup group, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (group.teamName.toLowerCase().contains(q)) return true;
    for (final CertificateSelectableEntry entry in group.submissions) {
      if (entry.submissionTitle.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  static bool matchesIndividualSearch({
    required CertificateTeamSubmissionGroup group,
    required String memberName,
    required String query,
  }) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (memberName.toLowerCase().contains(q)) return true;
    if (group.teamName.toLowerCase().contains(q)) return true;
    for (final CertificateSelectableEntry entry in group.submissions) {
      if (entry.submissionTitle.toLowerCase().contains(q)) return true;
    }
    return false;
  }
}
