import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../data/docs_registry.dart';
import '../data/idea_lifecycle_content.dart';
import '../data/problem_lifecycle_content.dart';
import '../data/roles_responsibilities_content.dart';
import '../models/doc_models.dart';
import '../services/docs_print.dart';
import '../services/docs_search_service.dart';
import '../widgets/documentation_chrome.dart';
import '../widgets/documentation_layout.dart';
import '../screens/pages/placeholder_doc_page.dart';

/// Host shell for all Hackz documentation pages.
class DocumentationShellScreen extends StatefulWidget {
  const DocumentationShellScreen({
    super.key,
    this.initialPageId = 'problem-lifecycle',
  });

  final String initialPageId;

  @override
  State<DocumentationShellScreen> createState() => _DocumentationShellScreenState();
}

class _DocumentationShellScreenState extends State<DocumentationShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<DocumentationScrollBodyState> _scrollBodyKey =
      GlobalKey<DocumentationScrollBodyState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late String _pageId;
  String? _activeSectionId;
  Set<String>? _filteredIds;
  bool _printMode = false;
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _pageId = widget.initialPageId;
    _ensureSectionKeys();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DocPageDefinition get _page => DocsRegistry.byId(_pageId);

  List<DocSectionSpec> get _sections => DocsRegistry.sectionsFor(_pageId);

  void _ensureSectionKeys() {
    for (final DocSectionSpec s in _sections) {
      _sectionKeys.putIfAbsent(s.id, GlobalKey.new);
    }
    if (_sections.isNotEmpty) {
      _activeSectionId ??= _sections.first.id;
    }
  }

  void _selectPage(String id) {
    setState(() {
      _pageId = id;
      _ensureSectionKeys();
      _activeSectionId = _sections.isEmpty ? null : _sections.first.id;
    });
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _onSearch(String q) {
    final List<DocPageDefinition> hits = DocsSearchService.search(
      pages: DocsRegistry.pages,
      query: q,
      extraCorpus: <String, List<String>>{
        'problem-lifecycle': ProblemLifecycleSections.searchCorpus,
        'idea-lifecycle': IdeaLifecycleSections.searchCorpus,
        'roles-responsibilities': RolesResponsibilitiesSections.searchCorpus,
      },
    );
    setState(() {
      _filteredIds = q.trim().isEmpty
          ? null
          : hits.map((DocPageDefinition p) => p.id).toSet();
    });
  }

  Future<void> _scrollToSection(String id) async {
    setState(() => _activeSectionId = id);
    await _scrollBodyKey.currentState?.scrollTo(id);
  }

  void _enterPrintMode() {
    setState(() => _printMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => docsPrintPage());
  }

  Widget _buildPageContent() {
    if (_pageId == 'problem-lifecycle') {
      return ProblemLifecycleDocBody(
        sectionKeys: _sectionKeys,
        onPrint: _enterPrintMode,
      );
    }
    if (_pageId == 'idea-lifecycle') {
      return IdeaLifecycleDocBody(
        sectionKeys: _sectionKeys,
        onPrint: _enterPrintMode,
      );
    }
    if (_pageId == 'roles-responsibilities') {
      return RolesResponsibilitiesDocBody(
        sectionKeys: _sectionKeys,
        onPrint: _enterPrintMode,
      );
    }
    if (_page.isPlaceholder) {
      return _page.builder(context);
    }
    return PlaceholderDocPage(title: _page.title, description: _page.description);
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = ResponsiveHelper.isDesktopOrWider(context);
    final DocPageDefinition? prev = DocsRegistry.previousOf(_pageId);
    final DocPageDefinition? next = DocsRegistry.nextOf(_pageId);

    final Widget scrollBody = DocumentationScrollBody(
      key: _scrollBodyKey,
      controller: _scrollController,
      sections: _sections,
      sectionKeys: _sectionKeys,
      onActiveSectionChanged: (String id) {
        if (_activeSectionId != id) {
          setState(() => _activeSectionId = id);
        }
      },
      mobileToc: desktop
          ? null
          : DocumentationTOC(
              sections: _sections,
              activeSectionId: _activeSectionId,
              onSelect: _scrollToSection,
              collapsible: true,
            ),
      footer: DocumentationFooter(
        previous: prev,
        next: next,
        onPrevious: prev == null ? null : () => _selectPage(prev.id),
        onNext: next == null ? null : () => _selectPage(next.id),
      ),
      children: <Widget>[_buildPageContent()],
    );

    final Widget layout = DocumentationLayout(
      pages: DocsRegistry.pages,
      selectedPage: _page,
      sections: _sections,
      activeSectionId: _activeSectionId,
      onSelectPage: _selectPage,
      onSelectSection: _scrollToSection,
      searchController: _searchController,
      onSearchChanged: _onSearch,
      filteredPageIds: _filteredIds,
      printMode: _printMode,
      body: scrollBody,
    );

    if (_printMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Print preview'),
          actions: <Widget>[
            TextButton(
              onPressed: () => setState(() => _printMode = false),
              child: const Text('Exit print'),
            ),
          ],
        ),
        body: layout,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: desktop
          ? null
          : DocumentationTopBar(
              title: 'Documentation',
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              trailing: <Widget>[
                IconButton(
                  tooltip: 'Print mode',
                  icon: const Icon(Icons.print_outlined),
                  onPressed: _enterPrintMode,
                ),
              ],
            ),
      drawer: desktop
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: DocumentationSearchBar(
                        controller: _searchController,
                        onChanged: _onSearch,
                      ),
                    ),
                    Expanded(
                      child: DocumentationSidebar(
                        pages: DocsRegistry.pages,
                        selectedId: _pageId,
                        onSelect: _selectPage,
                        filteredIds: _filteredIds,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: desktop
          ? Column(
              children: <Widget>[
                Material(
                  elevation: 0.5,
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          Icon(AppIcons.docs, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Hackz Documentation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _enterPrintMode,
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Print'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: layout),
              ],
            )
          : layout,
    );
  }
}
