import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'documentation_primitives.dart';

/// Mermaid diagram host — shows source everywhere; web can expand for future SVG inject.
class DocumentationMermaidDiagram extends StatelessWidget {
  const DocumentationMermaidDiagram({
    super.key,
    required this.source,
    this.title = 'Diagram',
  });

  final String source;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DocumentationCard(
      title: title,
      subtitle: kIsWeb
          ? 'Mermaid source — zoom-friendly code view (SVG-ready for future embed).'
          : 'Mermaid source — copy into any Mermaid renderer for SVG export.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DocumentationCodeBlock(
            code: source.trim(),
            language: 'mermaid',
            title: 'MERMAID',
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Prefer the visual timeline/infographic above for reading; use Mermaid when exporting diagrams.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
