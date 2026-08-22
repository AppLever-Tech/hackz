/// User-facing failure while fetching or identifying problems from an external source.
class ProblemSourceExtractException implements Exception {
  ProblemSourceExtractException(this.message);

  final String message;

  @override
  String toString() => message;
}
