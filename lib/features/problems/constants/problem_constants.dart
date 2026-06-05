class ProblemConstants {
  ProblemConstants._();

  static const String categorySoftware = 'Software';
  static const String categoryHardware = 'Hardware';

  static const List<String> categories = <String>[
    categorySoftware,
    categoryHardware,
  ];

  /// Returns the canonical category value when [raw] matches Software/Hardware
  /// (case-insensitive), otherwise `null`.
  static String? resolveCategory(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    for (final String category in categories) {
      if (category.toLowerCase() == trimmed.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  static bool isValidCategory(String raw) => resolveCategory(raw) != null;
}
