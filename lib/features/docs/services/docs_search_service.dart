import '../models/doc_models.dart';

/// Lightweight in-memory search over registered documentation pages.
abstract final class DocsSearchService {
  DocsSearchService._();

  static List<DocPageDefinition> search({
    required List<DocPageDefinition> pages,
    required String query,
    Map<String, List<String>>? extraCorpus,
  }) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return pages;

    return pages.where((DocPageDefinition page) {
      final StringBuffer buffer = StringBuffer()
        ..write(page.title)
        ..write(' ')
        ..write(page.description)
        ..write(' ')
        ..write(page.searchKeywords.join(' '));
      final List<String>? extra = extraCorpus?[page.id];
      if (extra != null) {
        for (final String line in extra) {
          buffer.write(' ');
          buffer.write(line);
        }
      }
      return buffer.toString().toLowerCase().contains(q);
    }).toList(growable: false);
  }
}
