/// Pulls candidate problem records from an external source as normalized import rows.
abstract class ProblemSourceExtractor {
  Future<List<Map<String, String>>> extract(String sourceUrl);
}
