import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_recipient_groups.dart';
import 'package:hackz/features/exports/certificate/certificate_selectable_entry.dart';

void main() {
  group('CertificateRecipientGroups', () {
    test('groups submissions by team', () {
      const CertificateSelectableEntry a1 = CertificateSelectableEntry(
        entryId: 'idea-1',
        teamId: 't1',
        teamName: 'Team Alpha',
        submissionTitle: 'Idea One',
        displayLabel: 'Team Alpha',
      );
      const CertificateSelectableEntry a2 = CertificateSelectableEntry(
        entryId: 'idea-2',
        teamId: 't1',
        teamName: 'Team Alpha',
        submissionTitle: 'Idea Two',
        displayLabel: 'Team Alpha',
      );
      const CertificateSelectableEntry b1 = CertificateSelectableEntry(
        entryId: 'idea-3',
        teamId: 't2',
        teamName: 'Team Beta',
        submissionTitle: 'Solo',
        displayLabel: 'Team Beta',
      );

      final List<CertificateTeamSubmissionGroup> groups =
          CertificateRecipientGroups.groupByTeam(<CertificateSelectableEntry>[a1, a2, b1]);

      expect(groups.length, 2);
      expect(groups.firstWhere((CertificateTeamSubmissionGroup g) => g.teamKey == 't1').submissions.length, 2);
    });

    test('individual keys are stable', () {
      const CertificateSelectableEntry entry = CertificateSelectableEntry(
        entryId: 'idea-1',
        teamId: 't1',
        teamName: 'Team Alpha',
        submissionTitle: 'Title',
        displayLabel: 'Team Alpha',
      );
      final String key = certificateIndividualSubmissionKey(userId: 'user-9', entry: entry);
      expect(key, 'user-9|idea-1');
    });

    test('search matches team or submission', () {
      const CertificateTeamSubmissionGroup group = CertificateTeamSubmissionGroup(
        teamKey: 't1',
        teamName: 'Team Alpha',
        submissions: <CertificateSelectableEntry>[
          CertificateSelectableEntry(
            entryId: 'i1',
            teamId: 't1',
            teamName: 'Team Alpha',
            submissionTitle: 'Smart Water',
            displayLabel: 'Team Alpha',
          ),
        ],
      );
      expect(CertificateRecipientGroups.matchesTeamSearch(group, 'water'), isTrue);
      expect(CertificateRecipientGroups.matchesTeamSearch(group, 'gamma'), isFalse);
    });
  });
}
