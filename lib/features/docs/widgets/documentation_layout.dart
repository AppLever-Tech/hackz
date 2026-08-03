import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../models/doc_models.dart';
import 'documentation_chrome.dart';

/// Shared documentation chrome: sidebar + content + sticky TOC.
class DocumentationLayout extends StatelessWidget {
  const DocumentationLayout({
    super.key,
    required this.pages,
    required this.selectedPage,
    required this.sections,
    required this.activeSectionId,
    required this.onSelectPage,
    required this.onSelectSection,
    required this.body,
    required this.searchController,
    required this.onSearchChanged,
    this.filteredPageIds,
    this.groupedPages,
    this.onSelectHome,
    this.printMode = false,
  });

  final List<DocPageDefinition> pages;
  final DocPageDefinition selectedPage;
  final List<DocSectionSpec> sections;
  final String? activeSectionId;
  final ValueChanged<String> onSelectPage;
  final ValueChanged<String> onSelectSection;
  final Widget body;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Set<String>? filteredPageIds;
  final List<(String title, List<DocPageDefinition> pages)>? groupedPages;
  final VoidCallback? onSelectHome;
  final bool printMode;

  @override
  Widget build(BuildContext context) {
    if (printMode) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: body,
        ),
      );
    }

    final bool desktop = ResponsiveHelper.isDesktopOrWider(context);
    if (desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 260,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: DocumentationSearchBar(
                      controller: searchController,
                      onChanged: onSearchChanged,
                    ),
                  ),
                  Expanded(
                    child: DocumentationSidebar(
                      pages: pages,
                      selectedId: selectedPage.id,
                      onSelect: onSelectPage,
                      filteredIds: filteredPageIds,
                      groupedPages: groupedPages,
                      onSelectHome: onSelectHome,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
          if (sections.isNotEmpty) ...<Widget>[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: DocumentationTOC(
                  sections: sections,
                  activeSectionId: activeSectionId,
                  onSelect: onSelectSection,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return body;
  }
}

/// Scrollable doc content with section visibility tracking for TOC.
class DocumentationScrollBody extends StatefulWidget {
  const DocumentationScrollBody({
    super.key,
    required this.controller,
    required this.sections,
    required this.onActiveSectionChanged,
    required this.sectionKeys,
    required this.children,
    this.header,
    this.footer,
    this.mobileToc,
  });

  final ScrollController controller;
  final List<DocSectionSpec> sections;
  final ValueChanged<String> onActiveSectionChanged;
  final Map<String, GlobalKey> sectionKeys;
  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final Widget? mobileToc;

  @override
  State<DocumentationScrollBody> createState() => DocumentationScrollBodyState();
}

class DocumentationScrollBodyState extends State<DocumentationScrollBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    String? active;
    double best = double.infinity;
    for (final DocSectionSpec section in widget.sections) {
      final GlobalKey? key = widget.sectionKeys[section.id];
      final BuildContext? ctx = key?.currentContext;
      if (ctx == null) continue;
      final RenderObject? ro = ctx.findRenderObject();
      if (ro is! RenderBox || !ro.hasSize) continue;
      final Offset offset = ro.localToGlobal(Offset.zero);
      final double dy = offset.dy - kToolbarHeight - 24;
      if (dy <= 80 && (80 - dy) < best) {
        best = 80 - dy;
        active = section.id;
      }
    }
    if (active != null) widget.onActiveSectionChanged(active);
  }

  Future<void> scrollTo(String sectionId) async {
    final GlobalKey? key = widget.sectionKeys[sectionId];
    final BuildContext? ctx = key?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = !ResponsiveHelper.isDesktopOrWider(context);
    return SelectionArea(
      child: ListView(
        controller: widget.controller,
        padding: EdgeInsets.fromLTRB(mobile ? 16 : 28, 20, mobile ? 16 : 28, 8),
        children: <Widget>[
          if (widget.header != null) ...<Widget>[widget.header!, const SizedBox(height: 20)],
          if (mobile && widget.mobileToc != null) ...<Widget>[
            widget.mobileToc!,
            const SizedBox(height: 16),
          ],
          ...widget.children,
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}
