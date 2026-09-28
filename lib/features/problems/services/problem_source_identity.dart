/// Catalogue origin used with [sourceProblemId] for idempotent SIH imports.
abstract final class ProblemSourceIdentity {
  static const String sih = 'SIH';
  static const String college = 'College';
  static const String external = 'External';

  static bool looksLikeSih({
    required String sourceProblemId,
    required String issuingOrganisation,
  }) {
    final String id = sourceProblemId.trim().toUpperCase();
    if (id.startsWith('SIH')) return true;
    final String org = issuingOrganisation.trim().toLowerCase();
    if (org.contains('smart india hackathon')) return true;
    return RegExp(r'(^|[^a-z])sih([^a-z]|$)').hasMatch(org);
  }

  /// Stored/inferred catalogue: SIH, College, or External.
  static String catalogSource({
    required String storedSource,
    required String sourceProblemId,
    required String issuingOrganisation,
  }) {
    final String stored = storedSource.trim();
    if (stored.toUpperCase() == sih) return sih;
    if (stored.toUpperCase() == college) return college;
    if (looksLikeSih(sourceProblemId: sourceProblemId, issuingOrganisation: issuingOrganisation)) {
      return sih;
    }
    if (stored.toUpperCase() == 'INTERNAL' || stored.isEmpty) return college;
    if (stored.toUpperCase() == 'EXTERNAL') return external;
    return stored;
  }

  static String resolveForImport({
    required String sourceProblemId,
    required String issuingOrganisation,
    required bool internal,
  }) {
    if (looksLikeSih(sourceProblemId: sourceProblemId, issuingOrganisation: issuingOrganisation)) {
      return sih;
    }
    return internal ? college : external;
  }

  /// Identity key `SOURCE|id`. Null when there is no original problem ID.
  static String? key(String catalogSource, String sourceProblemId) {
    final String id = sourceProblemId.trim();
    if (id.isEmpty) return null;
    final String catalog = catalogSource.trim().isEmpty ? college : catalogSource.trim();
    return '${catalog.toUpperCase()}|${id.toLowerCase()}';
  }
}
