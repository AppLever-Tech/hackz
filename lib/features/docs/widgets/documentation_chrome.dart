import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../models/doc_models.dart';

/// Sticky / collapsible "On This Page" TOC with active section highlight.
class DocumentationTOC extends StatelessWidget {
  const DocumentationTOC({
    super.key,
    required this.sections,
    required this.activeSectionId,
    required this.onSelect,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final List<DocSectionSpec> sections;
  final String? activeSectionId;
  final ValueChanged<String> onSelect;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map((DocSectionSpec s) {
        final bool active = s.id == activeSectionId;
        return InkWell(
          onTap: () => onSelect(s.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? cs.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(8),
              border: active
                  ? Border(left: BorderSide(color: cs.primary, width: 3))
                  : null,
            ),
            child: Text(
              s.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );

    if (!collapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'On this page',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          list,
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'On this page',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        children: <Widget>[list],
      ),
    );
  }
}

class DocumentationSearchBar extends StatelessWidget {
  const DocumentationSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search documentation…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: Icon(AppIcons.search, size: 18, color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
      ),
    );
  }
}

class DocumentationSidebar extends StatelessWidget {
  const DocumentationSidebar({
    super.key,
    required this.pages,
    required this.selectedId,
    required this.onSelect,
    this.filteredIds,
  });

  final List<DocPageDefinition> pages;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Set<String>? filteredIds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Iterable<DocPageDefinition> visible = filteredIds == null
        ? pages
        : pages.where((DocPageDefinition p) => filteredIds!.contains(p.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.docs, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Hackz Docs',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        ...visible.map((DocPageDefinition page) {
          final bool selected = page.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              selected: selected,
              selectedTileColor: cs.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(page.icon, size: 20, color: selected ? cs.primary : cs.onSurfaceVariant),
              title: Text(
                page.title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              subtitle: page.isPlaceholder
                  ? Text(
                      'Coming soon',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    )
                  : null,
              onTap: () => onSelect(page.id),
            ),
          );
        }),
      ],
    );
  }
}

class DocumentationTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DocumentationTopBar({
    super.key,
    required this.title,
    this.onMenu,
    this.trailing,
  });

  final String title;
  final VoidCallback? onMenu;
  final List<Widget>? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onMenu == null
          ? null
          : IconButton(icon: const Icon(AppIcons.menu), onPressed: onMenu),
      actions: trailing,
    );
  }
}

class DocumentationFooter extends StatelessWidget {
  const DocumentationFooter({
    super.key,
    this.previous,
    this.next,
    this.onPrevious,
    this.onNext,
  });

  final DocPageDefinition? previous;
  final DocPageDefinition? next;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 28),
      child: Row(
        children: <Widget>[
          if (previous != null)
            TextButton.icon(
              onPressed: onPrevious,
              icon: const Icon(AppIcons.chevronLeft),
              label: Text(previous!.title),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (next != null)
            TextButton.icon(
              onPressed: onNext,
              icon: const Icon(AppIcons.chevronRight),
              label: Text(next!.title),
              iconAlignment: IconAlignment.end,
            ),
        ],
      ),
    );
  }
}
