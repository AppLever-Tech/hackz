import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../models/doc_models.dart';
import '../../widgets/documentation_primitives.dart';
import '../../widgets/documentation_hero.dart';

/// Generic placeholder page for future documentation topics.
class PlaceholderDocPage extends StatelessWidget {
  const PlaceholderDocPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: title,
          description: description,
          readingMinutes: 3,
        ),
        const SizedBox(height: 20),
        DocumentationInfoCard(
          tone: DocInfoTone.note,
          title: 'Coming soon',
          body:
              'This page is registered in Hackz Help. Content will reuse the same layout, TOC, timeline, tables, and media widgets.',
        ),
        const SizedBox(height: 12),
        DocumentationCard(
          title: 'Planned sections',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('• Overview & hero'),
              Text('• Lifecycle / workflow'),
              Text('• Roles & actions'),
              Text('• FAQ'),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(AppIcons.docs, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('No layout changes required to publish this page.'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
