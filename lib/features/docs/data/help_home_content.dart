import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/services/user_role_labels.dart';
import '../data/docs_registry.dart';
import '../models/doc_models.dart';
import '../services/help_navigation.dart';
import '../widgets/documentation_hero.dart';
import '../widgets/documentation_primitives.dart';

/// Personalized Help landing content (Recommended + Browse All).
class HelpHomeDocBody extends StatelessWidget {
  const HelpHomeDocBody({
    super.key,
    required this.role,
    required this.onOpenPage,
    this.onPrint,
  });

  final UserRole role;
  final ValueChanged<String> onOpenPage;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final List<DocPageDefinition> recommended = DocsRegistry.recommendedPagesFor(role);
    final List<(DocCategory, List<DocPageDefinition>)> groups =
        DocsRegistry.groupedVisiblePages(role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DocumentationHero(
          title: HelpNavigation.roleGreeting(role),
          description: 'Learn how Hackz works and understand your responsibilities.',
          readingMinutes: 3,
          onPrint: onPrint,
        ),
        const SizedBox(height: 24),
        Text(
          'Recommended for You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Shortcuts tailored for ${UserRoleLabels.labelFor(role)}.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final int cols = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: recommended.map((DocPageDefinition page) {
                final double width =
                    cols == 1 ? c.maxWidth : (c.maxWidth - 12 * (cols - 1)) / cols;
                return SizedBox(
                  width: width,
                  child: _HelpLinkCard(page: page, onTap: () => onOpenPage(page.id)),
                );
              }).toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Browse All Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Explore every available guide for your role.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        for (final (DocCategory cat, List<DocPageDefinition> pages) in groups) ...<Widget>[
          DocumentationCard(
            title: cat.label,
            child: Column(
              children: pages
                  .map(
                    (DocPageDefinition page) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(page.icon, size: 20),
                      title: Text(
                        page.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        page.isPlaceholder ? 'Coming soon — ${page.description}' : page.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onOpenPage(page.id),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HelpLinkCard extends StatelessWidget {
  const _HelpLinkCard({required this.page, required this.onTap});

  final DocPageDefinition page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DocumentationCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(page.icon, color: cs.primary),
                const Spacer(),
                if (page.isPlaceholder)
                  DocumentationStatusPill(label: 'Soon', kind: DocStatusKind.inactive),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              page.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              page.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  'Open',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(AppIcons.chevronRight, size: 16, color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
