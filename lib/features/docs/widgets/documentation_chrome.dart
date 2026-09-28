import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../data/docs_registry.dart';
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
    this.hint = 'Search Help…',
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
    this.groupedPages,
    this.onSelectHome,
    this.brandTitle = 'Hackz Help',
  });

  final List<DocPageDefinition> pages;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final Set<String>? filteredIds;
  final List<(String title, List<DocPageDefinition> pages)>? groupedPages;
  final VoidCallback? onSelectHome;
  final String brandTitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool homeSelected = selectedId == DocsRegistry.helpHomeId;

    Widget tile(DocPageDefinition page) {
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
    }

    final List<Widget> body = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Row(
          children: <Widget>[
            Icon(AppIcons.docs, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              brandTitle,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
      if (onSelectHome != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            selected: homeSelected,
            selectedTileColor: cs.primary.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(
              Icons.home_outlined,
              size: 20,
              color: homeSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              'Help Home',
              style: TextStyle(
                fontWeight: homeSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            onTap: onSelectHome,
          ),
        ),
    ];

    if (filteredIds != null) {
      final Iterable<DocPageDefinition> visible =
          pages.where((DocPageDefinition p) => filteredIds!.contains(p.id));
      body.addAll(visible.map(tile));
    } else if (groupedPages != null) {
      for (final (String title, List<DocPageDefinition> group) in groupedPages!) {
        if (group.isEmpty) continue;
        body.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        );
        body.addAll(group.map(tile));
      }
    } else {
      body.addAll(pages.map(tile));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: body,
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
