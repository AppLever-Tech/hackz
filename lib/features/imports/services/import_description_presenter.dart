/// Presentation-only split of an import description. Never mutates import data.
class ImportDescriptionSection {
  const ImportDescriptionSection({this.heading, required this.body});

  final String? heading;
  final String body;
}

/// Detects common SIH/problem headings for Problem Preview only.
abstract final class ImportDescriptionPresenter {
  ImportDescriptionPresenter._();

  static const List<String> _known = <String>[
    'background',
    'description',
    'problem description',
    'problem statement',
    'about the problem',
    'summary',
    'expected solution',
    'expected outcome',
    'expected outcomes',
    'expected deliverables',
    'deliverables',
    'organization',
    'organisation',
    'issuing organisation',
    'issuing organization',
    'department',
    'issuing department',
    'category',
    'theme',
    'stakeholders',
    'stakeholder',
    'impact',
    'constraints',
    'success criteria',
    'research context',
    'innovation context',
    'feasibility',
    'timeline',
    'difficulty',
    'objective',
    'objectives',
    'challenge',
  ];

  static List<ImportDescriptionSection> present(String raw) {
    final String source = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (source.trim().isEmpty) return const <ImportDescriptionSection>[];

    final List<ImportDescriptionSection> structured = _structured(source);
    final int headings = structured.where((ImportDescriptionSection s) => (s.heading ?? '').isNotEmpty).length;
    if (headings >= 2) return structured;

    return _paragraphs(source);
  }

  static List<ImportDescriptionSection> _structured(String source) {
    final List<String> lines = source.split('\n');
    final List<ImportDescriptionSection> sections = <ImportDescriptionSection>[];
    String? heading;
    final StringBuffer body = StringBuffer();

    void flush() {
      final String text = body.toString().trim();
      if ((heading ?? '').isEmpty && text.isEmpty) return;
      sections.add(ImportDescriptionSection(heading: heading, body: text));
      heading = null;
      body.clear();
    }

    for (final String line in lines) {
      final String? detected = _headingOf(line);
      if (detected != null) {
        flush();
        heading = detected;
        continue;
      }
      if (body.isNotEmpty) body.writeln();
      body.write(line);
    }
    flush();
    return sections;
  }

  static String? _headingOf(String rawLine) {
    String line = rawLine.trim();
    if (line.isEmpty || line.length > 48) return null;
    line = line.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
    if (line.endsWith(':')) line = line.substring(0, line.length - 1).trim();
    final String key = line.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    if (key.isEmpty || !_known.contains(key)) return null;
    return _titleCase(line);
  }

  static String _titleCase(String raw) {
    return raw
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .map((String part) {
          if (part.length == 1) return part.toUpperCase();
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }

  static List<ImportDescriptionSection> _paragraphs(String source) {
    final List<String> parts = source
        .split(RegExp(r'\n\s*\n'))
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return <ImportDescriptionSection>[ImportDescriptionSection(body: source.trim())];
    }
    return parts.map((String part) => ImportDescriptionSection(body: part)).toList(growable: false);
  }
}
