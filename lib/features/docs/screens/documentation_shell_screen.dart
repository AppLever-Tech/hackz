import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../dashboard/chrome/dashboard_session_scope.dart';
import '../data/docs_registry.dart';
import '../data/help_home_content.dart';
import '../data/idea_lifecycle_content.dart';
import '../data/innovation_to_startup_content.dart';
import '../data/platform_overview_content.dart';
import '../data/problem_lifecycle_content.dart';
import '../data/roles_responsibilities_content.dart';
import '../models/doc_models.dart';
import '../services/docs_print.dart';
import '../services/docs_search_service.dart';
import '../widgets/documentation_chrome.dart';
import '../widgets/documentation_layout.dart';
import '../screens/pages/placeholder_doc_page.dart';

/// Host shell for all Hackz Help pages (docs feature, Help UI branding).
class DocumentationShellScreen extends StatefulWidget {
  const DocumentationShellScreen({
    super.key,
    this.initialPageId = DocsRegistry.helpHomeId,
    this.initialSectionId,
    this.user,
    this.standalone = false,
  });

  final String initialPageId;
  final String? initialSectionId;
  final UserModel? user;
  final bool standalone;

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
    if (widget.initialSectionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.initialSectionId!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  UserRole get _role {
    final UserModel? u =
        widget.user ?? DashboardSessionScope.maybeOf(context)?.user;
    if (u == null) return UserRole.student;
    return UserRole.fromCode(u.role);
  }

  List<DocPageDefinition> get _visiblePages => DocsRegistry.visiblePagesFor(_role);

  DocPageDefinition get _page => DocsRegistry.byId(_pageId);

  List<DocSectionSpec> get _sections => DocsRegistry.sectionsFor(_pageId);

  List<(String, List<DocPageDefinition>)> get _groupedPages =>
      DocsRegistry.groupedVisiblePages(_role)
          .map(((DocCategory, List<DocPageDefinition>) e) => (e.$1.label, e.$2))
          .toList(growable: false);

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
      pages: _visiblePages,
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
    if (_pageId == DocsRegistry.helpHomeId) {
      return HelpHomeDocBody(
        role: _role,
        onOpenPage: _selectPage,
        onPrint: _enterPrintMode,
      );
    }
    if (_pageId == 'platform-overview') {
      return PlatformOverviewDocBody(
        sectionKeys: _sectionKeys,
        onOpenPage: _selectPage,
        onPrint: _enterPrintMode,
      );
    }
    if (_pageId == 'innovation-to-startup') {
      return InnovationToStartupDocBody(
        sectionKeys: _sectionKeys,
        onOpenPage: _selectPage,
        onPrint: _enterPrintMode,
      );
    }
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

  Widget _sidebar() {
    return DocumentationSidebar(
      pages: _visiblePages,
      selectedId: _pageId,
      onSelect: _selectPage,
      filteredIds: _filteredIds,
      groupedPages: _filteredIds == null ? _groupedPages : null,
      onSelectHome: () => _selectPage(DocsRegistry.helpHomeId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = ResponsiveHelper.isDesktopOrWider(context);
    final bool isHome = _pageId == DocsRegistry.helpHomeId;
    final DocPageDefinition? prev =
        isHome ? null : DocsRegistry.previousOf(_pageId, among: _visiblePages);
    final DocPageDefinition? next =
        isHome ? null : DocsRegistry.nextOf(_pageId, among: _visiblePages);

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
      mobileToc: desktop || _sections.isEmpty
          ? null
          : DocumentationTOC(
              sections: _sections,
              activeSectionId: _activeSectionId,
              onSelect: _scrollToSection,
              collapsible: true,
            ),
      footer: isHome
          ? null
          : DocumentationFooter(
              previous: prev,
              next: next,
              onPrevious: prev == null ? null : () => _selectPage(prev.id),
              onNext: next == null ? null : () => _selectPage(next.id),
            ),
      children: <Widget>[_buildPageContent()],
    );

    final Widget layout = DocumentationLayout(
      pages: _visiblePages,
      selectedPage: _page,
      sections: _sections,
      activeSectionId: _activeSectionId,
      onSelectPage: _selectPage,
      onSelectSection: _scrollToSection,
      searchController: _searchController,
      onSearchChanged: _onSearch,
      filteredPageIds: _filteredIds,
      groupedPages: _filteredIds == null ? _groupedPages : null,
      onSelectHome: () => _selectPage(DocsRegistry.helpHomeId),
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

    final List<Widget> topTrailing = <Widget>[
      if (widget.standalone)
        IconButton(
          tooltip: 'Close Help',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      IconButton(
        tooltip: 'Print',
        icon: const Icon(Icons.print_outlined),
        onPressed: _enterPrintMode,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: desktop
          ? null
          : DocumentationTopBar(
              title: 'Help',
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              trailing: topTrailing,
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
                    Expanded(child: _sidebar()),
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
                          if (widget.standalone) ...<Widget>[
                            IconButton(
                              tooltip: 'Back',
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Icon(AppIcons.docs, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Hackz Help',
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
