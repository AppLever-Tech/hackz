import '../models/problem_model.dart';

bool hasDuplicateTitle(String title, List<ProblemModel> problems) =>
    ProblemTitleDisplay.hasDuplicateTitle(title, problems);

bool hasDuplicateTitleValue(String title, Iterable<String> titles) {
  final String key = title.trim().toLowerCase();
  if (key.isEmpty) return false;
  var count = 0;
  for (final String candidate in titles) {
    if (candidate.trim().toLowerCase() != key) continue;
    count++;
    if (count > 1) return true;
  }
  return false;
}

/// List-scoped title labels. SIH IDs appear only when the same title repeats.
abstract final class ProblemTitleDisplay {
  static bool hasDuplicateTitle(String title, List<ProblemModel> problems) {
    return hasDuplicateTitleValue(
      title,
      problems.map((ProblemModel problem) => problem.title),
    );
  }

  static String forProblem(
    ProblemModel problem,
    List<ProblemModel> problems, {
    String emptyTitle = 'Untitled',
  }) {
    final String title = problem.title.trim().isEmpty ? emptyTitle : problem.title.trim();
    if (!hasDuplicateTitle(problem.title, problems)) return title;
    final String id = problem.sourceProblemId.trim();
    if (id.isEmpty) return title;
    return '$id - $title';
  }
}
