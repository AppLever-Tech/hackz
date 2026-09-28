class EvaluationAssignmentConflict {
  const EvaluationAssignmentConflict({
    required this.isConflict,
    required this.reasons,
  });

  const EvaluationAssignmentConflict.none()
      : isConflict = false,
        reasons = const <String>[];

  final bool isConflict;
  final List<String> reasons;
}
