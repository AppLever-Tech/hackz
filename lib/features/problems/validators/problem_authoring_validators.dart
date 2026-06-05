import '../constants/problem_constants.dart';

/// Publish-time validation for the problem authoring workspace.
///
/// All helpers are pure functions returning either `null` (valid) or a
/// short user-facing error string. The authoring workspace surfaces the
/// first non-null result in a snackbar before save.
abstract final class ProblemAuthoringValidators {
  ProblemAuthoringValidators._();

  static String? validateCategory(String category) {
    if (ProblemConstants.isValidCategory(category)) return null;
    return 'Category must be Software or Hardware.';
  }

  /// Validates `maxIdeasAllowed` against the org-level upper bound.
  ///
  /// `value == null` is allowed (means "use org default"). When supplied, it
  /// must be in `[1, orgMaxAllowed]`.
  static String? validateMaxIdeasAllowed(int? value, int orgMaxAllowed) {
    if (value == null) return null;
    if (value < 1) return 'Max ideas must be at least 1.';
    if (value > orgMaxAllowed) {
      return 'Max ideas cannot exceed the organization limit ($orgMaxAllowed).';
    }
    return null;
  }

  /// Validates `ideaSubmissionDeadline`. `null` is allowed (no deadline).
  /// When set, it must be in the future relative to [now].
  static String? validateDeadline(DateTime? deadline, {DateTime? now}) {
    if (deadline == null) return null;
    final DateTime resolvedNow = now ?? DateTime.now();
    if (!deadline.isAfter(resolvedNow)) {
      return 'Submission deadline must be in the future.';
    }
    return null;
  }

  /// Validates per-problem team-size bounds.
  ///
  /// Either bound may be `null` (means "use org default"). When both are
  /// supplied, `min <= max`. When either is supplied, it must fit inside the
  /// org-level `[orgMin, orgMax]` band.
  static String? validateTeamSize({
    required int? min,
    required int? max,
    required int orgMin,
    required int orgMax,
  }) {
    if (min != null && max != null && min > max) {
      return 'Minimum team size must be less than or equal to maximum.';
    }
    if (min != null && (min < orgMin || min > orgMax)) {
      return 'Minimum team size must be between $orgMin and $orgMax.';
    }
    if (max != null && (max < orgMin || max > orgMax)) {
      return 'Maximum team size must be between $orgMin and $orgMax.';
    }
    return null;
  }
}
