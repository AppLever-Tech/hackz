import 'certificate_data.dart';
import 'certificate_data_factory.dart';
import 'certificate_organisation_logo_loader.dart';
import 'certificate_event_context.dart';
import 'certificate_generation_plan.dart';
import 'certificate_selectable_entry.dart';
import 'certificate_team_member_loader.dart';
import 'certificate_type.dart';

/// Expands UI selections into [CertificateData] rows for the Phase 1 renderer.
abstract final class CertificateGenerationService {
  CertificateGenerationService._();

  static CertificateGenerationPlan plan({
    required CertificateEventContext event,
    required CertificateType certificateType,
    required CertificateRecipientType recipientType,
    required List<CertificateSelectableEntry> selectedEntries,
    Map<String, List<CertificateMember>> membersByTeam = const <String, List<CertificateMember>>{},
    Set<String> selectedIndividualKeys = const <String>{},
  }) {
    final int count = _estimateCount(
      recipientType: recipientType,
      selectedEntries: selectedEntries,
      membersByTeam: membersByTeam,
      selectedIndividualKeys: selectedIndividualKeys,
    );
    final CertificateOutputMode mode = count <= 1
        ? CertificateOutputMode.singlePdf
        : (count <= CertificateBatchPolicy.directPdfMaxCertificates
              ? CertificateOutputMode.multiPagePdf
              : CertificateOutputMode.zipArchive);
    return CertificateGenerationPlan(
      certificateType: certificateType,
      recipientType: recipientType,
      selectedEntries: selectedEntries,
      estimatedCertificates: count,
      outputMode: mode,
    );
  }

  static int estimateCount({
    required CertificateRecipientType recipientType,
    required List<CertificateSelectableEntry> selectedEntries,
    Map<String, List<CertificateMember>> membersByTeam = const <String, List<CertificateMember>>{},
  }) {
    return _estimateCount(
      recipientType: recipientType,
      selectedEntries: selectedEntries,
      membersByTeam: membersByTeam,
    );
  }

  static Future<List<CertificateData>> buildCertificateData({
    required CertificateEventContext event,
    required CertificateGenerationPlan plan,
    Map<String, List<CertificateMember>> membersByTeam = const <String, List<CertificateMember>>{},
    Set<String> selectedIndividualKeys = const <String>{},
    List<CertificateSignatory> signatories = const <CertificateSignatory>[],
  }) async {
    final orgLogo = await CertificateOrganisationLogoLoader.loadForOrg(event.organisationId);
    Map<String, List<CertificateMember>> members = membersByTeam;
    if (plan.recipientType == CertificateRecipientType.individual && members.isEmpty) {
      members = await CertificateTeamMemberLoader.membersByTeamId(
        plan.selectedEntries.map((CertificateSelectableEntry e) => e.teamId),
      );
    }
    final List<CertificateData> out = <CertificateData>[];
    if (plan.recipientType == CertificateRecipientType.individual && selectedIndividualKeys.isNotEmpty) {
      final Map<String, CertificateSelectableEntry> entriesById = <String, CertificateSelectableEntry>{
        for (final CertificateSelectableEntry e in plan.selectedEntries) e.entryId.trim(): e,
      };
      for (final String key in selectedIndividualKeys) {
        final _IndividualKeyParts? parts = _IndividualKeyParts.parse(key);
        if (parts == null) continue;
        final CertificateSelectableEntry? entry = entriesById[parts.entryId];
        if (entry == null) continue;
        final String recipientName = _memberDisplayName(members, entry.teamId, parts.userId, entry.displayLabel);
        out.add(
          CertificateDataFactory.build(
            event: event,
            certificateType: plan.certificateType,
            recipientType: CertificateRecipientType.individual,
            recipientName: recipientName,
            entry: entry,
            signatories: signatories,
            organisationLogo: orgLogo,
          ),
        );
      }
      return out;
    }

    for (final CertificateSelectableEntry entry in plan.selectedEntries) {
      if (plan.recipientType == CertificateRecipientType.team) {
        out.add(
          CertificateDataFactory.build(
            event: event,
            certificateType: plan.certificateType,
            recipientType: CertificateRecipientType.team,
            recipientName: entry.displayLabel,
            entry: entry,
            signatories: signatories,
            organisationLogo: orgLogo,
          ),
        );
        continue;
      }
      final List<CertificateMember> roster = members[entry.teamId.trim()] ?? const <CertificateMember>[];
      if (roster.isEmpty) {
        out.add(
          CertificateDataFactory.build(
            event: event,
            certificateType: plan.certificateType,
            recipientType: CertificateRecipientType.individual,
            recipientName: entry.displayLabel,
            entry: entry,
            signatories: signatories,
            organisationLogo: orgLogo,
          ),
        );
        continue;
      }
      for (final CertificateMember member in roster) {
        out.add(
          CertificateDataFactory.build(
            event: event,
            certificateType: plan.certificateType,
            recipientType: CertificateRecipientType.individual,
            recipientName: member.displayName,
            entry: entry,
            signatories: signatories,
            organisationLogo: orgLogo,
          ),
        );
      }
    }
    return out;
  }

  static String _memberDisplayName(
    Map<String, List<CertificateMember>> members,
    String teamId,
    String userId,
    String fallback,
  ) {
    for (final CertificateMember member in members[teamId.trim()] ?? const <CertificateMember>[]) {
      if (member.userId.trim() == userId.trim()) return member.displayName;
    }
    return fallback;
  }

  static List<CertificateSelectableEntry> defaultSelection({
    required CertificateEventContext event,
    required CertificateType type,
  }) {
    return switch (type) {
      CertificateType.participation => List<CertificateSelectableEntry>.from(event.participationEntries),
      CertificateType.winner =>
        event.winnerEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.winnerEntry!],
      CertificateType.runnerUp =>
        event.runnerUpEntry == null ? const <CertificateSelectableEntry>[] : <CertificateSelectableEntry>[event.runnerUpEntry!],
    };
  }

  static int _estimateCount({
    required CertificateRecipientType recipientType,
    required List<CertificateSelectableEntry> selectedEntries,
    required Map<String, List<CertificateMember>> membersByTeam,
    Set<String> selectedIndividualKeys = const <String>{},
  }) {
    if (selectedEntries.isEmpty && selectedIndividualKeys.isEmpty) return 0;
    if (recipientType == CertificateRecipientType.individual && selectedIndividualKeys.isNotEmpty) {
      return selectedIndividualKeys.length;
    }
    if (recipientType == CertificateRecipientType.team) return selectedEntries.length;
    int total = 0;
    for (final CertificateSelectableEntry entry in selectedEntries) {
      final List<CertificateMember> roster = membersByTeam[entry.teamId.trim()] ?? const <CertificateMember>[];
      total += roster.isEmpty ? 1 : roster.length;
    }
    return total;
  }
}

class _IndividualKeyParts {
  const _IndividualKeyParts({required this.userId, required this.entryId});

  final String userId;
  final String entryId;

  static _IndividualKeyParts? parse(String key) {
    final int sep = key.indexOf('|');
    if (sep <= 0) return null;
    final String userId = key.substring(0, sep).trim();
    final String entryId = key.substring(sep + 1).trim();
    if (userId.isEmpty || entryId.isEmpty) return null;
    return _IndividualKeyParts(userId: userId, entryId: entryId);
  }
}
