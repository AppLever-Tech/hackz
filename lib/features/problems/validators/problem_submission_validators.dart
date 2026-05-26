import '../models/problem_model.dart';

/// Result of evaluating whether an idea can be submitted against a problem.
///
/// A gate is built from a [ProblemModel] plus the current idea count and the
/// org-level default cap (read from `OrgSettings.defaultMaxIdeasPerProblem`).
/// Both the [ProblemCard] (passive indicators / Submit button states) and the
/// innovation submission workspace (active save-time guard) consume the same
/// gate so the message stays consistent across the app.
enum IdeaSubmissionGateState {
  /// Submissions are accepted.
  open,

  /// `ideaSubmissionDeadline` has passed.
  deadlinePassed,

  /// `submittedCount >= effectiveMaxIdeas`.
  limitReached,

  /// The problem itself has been deactivated by the org.
  inactive,
}

/// Submission-control snapshot for a single problem. Cheap to construct and
/// safe to keep on the widget tree.
class IdeaSubmissionGate {
  const IdeaSubmissionGate({
    required this.state,
    required this.submittedCount,
    required this.effectiveMaxIdeas,
    required this.now,
    this.deadline,
  });

  final IdeaSubmissionGateState state;

  /// Number of ideas already submitted against the problem.
  final int submittedCount;

  /// Resolved per-problem cap (problem.maxIdeasAllowed ?? org default).
  final int effectiveMaxIdeas;

  /// Submission deadline, when configured.
  final DateTime? deadline;

  /// Frozen "now" used to compute the gate. Kept so consumers can render a
  /// stable "Closes in X" string without re-reading the clock.
  final DateTime now;

  bool get canSubmit => state == IdeaSubmissionGateState.open;

  /// Remaining slots when [state] is [IdeaSubmissionGateState.open] or
  /// [IdeaSubmissionGateState.deadlinePassed]. Clamped to >= 0.
  int get remaining {
    final int diff = effectiveMaxIdeas - submittedCount;
    return diff < 0 ? 0 : diff;
  }

  /// Time until the deadline, if set and still in the future.
  Duration? get timeUntilDeadline {
    final DateTime? d = deadline;
    if (d == null) return null;
    final Duration diff = d.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// Computes [IdeaSubmissionGate] for a problem. Pure, side-effect free.
///
/// `orgDefaultMaxIdeas` is the value of
/// `OrgSettings.defaultMaxIdeasPerProblem` (already loaded by the caller).
/// `now` defaults to `DateTime.now()` and is exposed mainly for tests.
IdeaSubmissionGate computeIdeaSubmissionGate({
  required ProblemModel problem,
  required int submittedCount,
  required int orgDefaultMaxIdeas,
  DateTime? now,
}) {
  final DateTime resolvedNow = now ?? DateTime.now();
  final int effectiveMax = problem.maxIdeasAllowed ?? orgDefaultMaxIdeas;
  final DateTime? deadline = problem.ideaSubmissionDeadline;

  final IdeaSubmissionGateState state;
  if (!problem.isActive) {
    state = IdeaSubmissionGateState.inactive;
  } else if (deadline != null && resolvedNow.isAfter(deadline)) {
    state = IdeaSubmissionGateState.deadlinePassed;
  } else if (submittedCount >= effectiveMax) {
    state = IdeaSubmissionGateState.limitReached;
  } else {
    state = IdeaSubmissionGateState.open;
  }

  return IdeaSubmissionGate(
    state: state,
    submittedCount: submittedCount,
    effectiveMaxIdeas: effectiveMax,
    deadline: deadline,
    now: resolvedNow,
  );
}

/// Reason describing why a submission is blocked. Used by the submission
/// workspace to render a snackbar identical to the problem-card pill.
String describeBlockedReason(IdeaSubmissionGate gate) {
  switch (gate.state) {
    case IdeaSubmissionGateState.open:
      return '';
    case IdeaSubmissionGateState.deadlinePassed:
      return 'Submission window has closed for this problem.';
    case IdeaSubmissionGateState.limitReached:
      return 'Idea limit reached (${gate.submittedCount}/${gate.effectiveMaxIdeas}).';
    case IdeaSubmissionGateState.inactive:
      return 'This problem is no longer accepting submissions.';
  }
}
