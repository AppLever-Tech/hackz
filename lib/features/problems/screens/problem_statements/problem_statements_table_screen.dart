import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../../../models/user_model.dart';
import '../../../../responsive/responsive_helper.dart';
import '../../../../screens/common/dashboard_chrome_scope.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../../../widgets/faculty/innovation_submission_workspace.dart';
import '../../../../widgets/loading/hkz_progress_indicator.dart';
import '../../../../workspace/workspace.dart';
import '../../../org_settings/constants/org_setting_keys.dart';
import '../../../org_settings/services/org_settings_service.dart';
import '../../models/problem_list_config.dart';
import '../../models/problem_model.dart';
import '../../services/problem_query_service.dart';
import '../../validators/problem_submission_validators.dart';
import '../../widgets/problem_filters_panel.dart';
import '../../widgets/problem_metrics_row.dart';
import 'problem_statement_details_pane.dart';

/// Tabular view of problem statements from [FirestoreUtils.hkzProblems].
class ProblemStatementsTableScreen extends StatefulWidget {
  const ProblemStatementsTableScreen({
    super.key,
    required this.currentUser,
    required this.config,
  });

  final UserModel currentUser;
  final ProblemListConfig config;

  @override
  State<ProblemStatementsTableScreen> createState() => _ProblemStatementsTableScreenState();
}

class _ProblemStatementsTableScreenState extends State<ProblemStatementsTableScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<ProblemListQueryResult>? _problemsFuture;
  List<ProblemModel> _lastLoaded = <ProblemModel>[];
  ProblemDashboardMetrics _metrics = ProblemDashboardMetrics.empty;
  Map<String, int> _ideaCountByProblemId = <String, int>{};
  int _orgDefaultMaxIdeas = 50;
  ProblemSortType _sort = ProblemSortType.newest;

  // Mirrors the filter state in `ProblemsListScreen` so the same
  // [ProblemFiltersPanel] / [ProblemActiveFiltersRow] widgets can drive both
  // screens. Defaults to "no filter" (i.e. show everything).
  bool _showFilters = false;
  bool? _statusFilter;
  bool? _hasAttachments;
  Set<String> _departmentFilters = <String>{};
  Set<String> _tagFilters = <String>{};

  static const List<_TableColumn> _columns = <_TableColumn>[
    _TableColumn(label: 'PS #', flex: 2, minWidth: 72),
    _TableColumn(label: 'Title', flex: 12, minWidth: 240),
    _TableColumn(label: 'Department', flex: 4, minWidth: 128),
    _TableColumn(label: 'Category', flex: 3, minWidth: 88),
    _TableColumn(label: 'Status', flex: 2, minWidth: 88),
    _TableColumn(label: 'Ideas', flex: 1, minWidth: 56, align: TextAlign.center),
    _TableColumn(label: 'Actions', flex: 2, minWidth: 96, align: TextAlign.end),
  ];

  @override
  void initState() {
    super.initState();
    _sort = widget.config.enabledSorts.contains(ProblemSortType.newest)
        ? ProblemSortType.newest
        : widget.config.enabledSorts.first;
    _loadProblems();
    _loadOrgDefaultMaxIdeas();
    _searchController.addListener(_onSearchChanged);
  }

  /// Reads org-scoped default-max-ideas so the submission gate can resolve
  /// when a problem doesn't carry its own per-problem override.
  Future<void> _loadOrgDefaultMaxIdeas() async {
    try {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.config.orgId);
      if (!mounted) return;
      final Map<String, dynamic> values = OrgSettingsService.instance.valuesSnapshot;
      final int defMax =
          (values[OrgSettingKeys.defaultMaxIdeasPerProblem] as num?)?.toInt() ?? 50;
      if (defMax != _orgDefaultMaxIdeas) {
        setState(() => _orgDefaultMaxIdeas = defMax);
      }
    } catch (_) {
      // Fallback already applied.
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadProblems);
  }

  void _loadProblems() {
    setState(() {
      _problemsFuture = ProblemQueryService.fetchProblems(
        ProblemQueryParams(
          config: widget.config,
          search: _searchController.text,
          sortType: _sort,
          statusFilter: _statusFilter,
          departmentFilters: _departmentFilters,
          tagFilters: _tagFilters,
          hasAttachments: _hasAttachments,
        ),
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = null;
      _hasAttachments = null;
      _departmentFilters = <String>{};
      _tagFilters = <String>{};
    });
    _loadProblems();
  }

  bool get _hasAnyActiveFilter =>
      _departmentFilters.isNotEmpty ||
      _tagFilters.isNotEmpty ||
      _statusFilter != null ||
      _hasAttachments != null;

  Future<void> _openSubmitIdea(ProblemModel problem) async {
    final IdeaSubmissionGate gate = computeIdeaSubmissionGate(
      problem: problem,
      submittedCount: _ideaCountByProblemId[problem.problemId] ?? 0,
      orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
    );
    final created = await showInnovationSubmissionWorkspace(
      context: context,
      currentUser: widget.currentUser,
      problem: problem,
      gate: gate,
    );
    if (created == true && mounted) _loadProblems();
  }

  void _openDetails(ProblemModel problem) {
    WorkspaceController.instance.close();
    final chrome = DashboardChromeScope.of(context);
    chrome.showOverlay(
      ProblemStatementDetailsPane(
        key: ValueKey<String>(problem.problemId),
        problem: problem,
        onBack: chrome.clearOverlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProblemListQueryResult>(
      future: _problemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load problem statements: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        final ProblemListQueryResult result = snapshot.data ??
            ProblemListQueryResult(
              items: _lastLoaded,
              metrics: _metrics,
              ideaCountByProblemId: _ideaCountByProblemId,
            );
        final problems = result.items;
        _lastLoaded = problems;
        _metrics = result.metrics;
        _ideaCountByProblemId = result.ideaCountByProblemId;

        // Filter facets come from the currently loaded page only — matches
        // the cards-based list screen behaviour so the two surfaces stay
        // visually consistent.
        final allDepartments = problems
            .map((p) => p.departmentDisplayName.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
        final allTags = problems
            .expand((p) => p.tags)
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final tableMinWidth = _columns.fold<double>(0, (sum, c) => sum + c.minWidth) + 32;

            final tableBody = problems.isEmpty
                ? _EmptyTableState(onClearSearch: () {
                    _searchController.clear();
                    _loadProblems();
                  })
                : _ProblemStatementsTable(
                    problems: problems,
                    ideaCountByProblemId: _ideaCountByProblemId,
                    columns: _columns,
                    minWidth: tableMinWidth,
                    canSubmitIdea: widget.config.canSubmitIdea,
                    onOpenProblem: (problem) => WorkspaceNavigator.openProblem(context, problem.problemId),
                    onOpenDetails: _openDetails,
                    onSubmitIdea: _openSubmitIdea,
                  );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ProblemMetricsRow(metrics: _metrics),
                const SizedBox(height: 12),
                _buildToolbar(context),
                const SizedBox(height: 12),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: ProblemFiltersPanel(
                    enabledFilters: widget.config.enabledFilters,
                    allDepartments: allDepartments,
                    allTags: allTags,
                    departmentFilters: _departmentFilters,
                    tagFilters: _tagFilters,
                    statusFilter: _statusFilter,
                    hasAttachments: _hasAttachments,
                    onDepartmentToggle: (d, selected) => setState(() {
                      if (selected) {
                        _departmentFilters.add(d);
                      } else {
                        _departmentFilters.remove(d);
                      }
                    }),
                    onTagToggle: (t, selected) => setState(() {
                      if (selected) {
                        _tagFilters.add(t);
                      } else {
                        _tagFilters.remove(t);
                      }
                    }),
                    onStatusChange: (next) => setState(() => _statusFilter = next),
                    onAttachmentsChange: (next) => setState(() => _hasAttachments = next),
                    onClearAll: _clearAllFilters,
                    onApply: _loadProblems,
                  ),
                  crossFadeState: _showFilters
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
                if (_hasAnyActiveFilter) ...<Widget>[
                  const SizedBox(height: 12),
                  ProblemActiveFiltersRow(
                    departmentFilters: _departmentFilters,
                    tagFilters: _tagFilters,
                    statusFilter: _statusFilter,
                    hasAttachments: _hasAttachments,
                    onRemoveDepartment: (d) {
                      setState(() => _departmentFilters.remove(d));
                      _loadProblems();
                    },
                    onRemoveTag: (t) {
                      setState(() => _tagFilters.remove(t));
                      _loadProblems();
                    },
                    onClearStatus: () {
                      setState(() => _statusFilter = null);
                      _loadProblems();
                    },
                    onClearAttachments: () {
                      setState(() => _hasAttachments = null);
                      _loadProblems();
                    },
                  ),
                ],
                const SizedBox(height: 10),
                if (hasBoundedHeight)
                  Expanded(child: tableBody)
                else
                  SizedBox(height: 480, child: tableBody),
              ],
            );

            return content;
          },
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final searchField = TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadProblems(),
      decoration: InputDecoration(
        hintText: 'Search problem number, title, department, tags…',
        prefixIcon: const Icon(AppIcons.search),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFCFDFF),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: mobile ? 10 : 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.3),
        ),
      ),
    );

    final filterButton = OutlinedButton.icon(
      onPressed: () => setState(() => _showFilters = !_showFilters),
      icon: const Icon(Icons.tune, size: 18),
      label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
      style: _outlinedToolbarStyle(context),
    );

    final sortButton = _buildSortButton(context);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          searchField,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[filterButton, sortButton],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: searchField),
        const SizedBox(width: 8),
        filterButton,
        const SizedBox(width: 8),
        sortButton,
      ],
    );
  }

  ButtonStyle _outlinedToolbarStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: const Color(0xFFFCFDFF),
        side: const BorderSide(color: Color(0xFFD9E2F5), width: 1.2),
      );

  Widget _buildSortButton(BuildContext context) {
    return MenuAnchor(
      menuChildren: _availableSorts
          .map(
            (ProblemSortType sort) => MenuItemButton(
              onPressed: () {
                setState(() => _sort = sort);
                _loadProblems();
              },
              child: Text(_sortLabel(sort)),
            ),
          )
          .toList(growable: false),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.swap_vert, size: 18),
          label: Text(_sortLabel(_sort)),
          style: _outlinedToolbarStyle(context),
        );
      },
    );
  }

  String _sortLabel(ProblemSortType type) {
    switch (type) {
      case ProblemSortType.newest:
        return 'Newest';
      case ProblemSortType.oldest:
        return 'Oldest';
      case ProblemSortType.titleAZ:
        return 'Title A-Z';
      case ProblemSortType.department:
        return 'Department';
    }
  }

  List<ProblemSortType> get _availableSorts {
    const order = <ProblemSortType>[
      ProblemSortType.newest,
      ProblemSortType.oldest,
      ProblemSortType.titleAZ,
      ProblemSortType.department,
    ];
    return order.where((sort) => widget.config.enabledSorts.contains(sort)).toList(growable: false);
  }
}

class _TableColumn {
  const _TableColumn({
    required this.label,
    required this.flex,
    required this.minWidth,
    this.align = TextAlign.start,
  });

  final String label;
  final int flex;
  final double minWidth;
  final TextAlign align;
}

class _ProblemStatementsTable extends StatelessWidget {
  const _ProblemStatementsTable({
    required this.problems,
    required this.ideaCountByProblemId,
    required this.columns,
    required this.minWidth,
    required this.canSubmitIdea,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
  });

  final List<ProblemModel> problems;
  final Map<String, int> ideaCountByProblemId;
  final List<_TableColumn> columns;
  final double minWidth;
  final bool canSubmitIdea;
  final ValueChanged<ProblemModel> onOpenProblem;
  final ValueChanged<ProblemModel> onOpenDetails;
  final ValueChanged<ProblemModel> onSubmitIdea;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool needsHorizontalScroll =
                constraints.maxWidth.isFinite && constraints.maxWidth < minWidth;

            final Widget table = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TableHeaderRow(columns: columns),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problem = problems[index];
                      return _TableDataRow(
                        problem: problem,
                        columns: columns,
                        striped: index.isOdd,
                        ideaCount: ideaCountByProblemId[problem.problemId] ?? 0,
                        canSubmitIdea: canSubmitIdea,
                          onOpenProblem: () => onOpenProblem(problem),
                          onOpenDetails: () => onOpenDetails(problem),
                          onSubmitIdea: () => onSubmitIdea(problem),
                      );
                    },
                  ),
                ),
              ],
            );

            if (!needsHorizontalScroll) {
              return table;
            }

            return Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (ScrollNotification notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: minWidth, child: table),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.columns});

  final List<_TableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF5F3FF), Color(0xFFEEF4FF)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: columns
            .map(
              (col) => Expanded(
                flex: col.flex,
                child: Text(
                  col.label.toUpperCase(),
                  textAlign: col.align,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.problem,
    required this.columns,
    required this.striped,
    required this.ideaCount,
    required this.canSubmitIdea,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
  });

  final ProblemModel problem;
  final List<_TableColumn> columns;
  final bool striped;
  final int ideaCount;
  final bool canSubmitIdea;
  final VoidCallback onOpenProblem;
  final VoidCallback onOpenDetails;
  final VoidCallback onSubmitIdea;

  @override
  Widget build(BuildContext context) {
    final String number = problem.problemNumber.trim().isEmpty ? '—' : problem.problemNumber.trim();
    final String title = problem.title.trim().isEmpty ? 'Untitled' : problem.title.trim();
    final String department = problem.departmentDisplayName.trim().isEmpty ? '—' : problem.departmentDisplayName.trim();
    final String category = problem.category.trim().isEmpty ? '—' : problem.category.trim();

    return Material(
      color: striped ? const Color(0xFFF8FAFC) : const Color(0xFFFCFDFF),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEF2F7))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: columns[0].flex,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A38FF),
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: columns[1].flex,
                child: InkWell(
                  onTap: onOpenDetails,
                  borderRadius: BorderRadius.circular(6),
                  hoverColor: const Color(0xFFEEF2FF),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                        height: 1.35,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0x334F46E5),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: columns[2].flex,
                child: Text(
                  department,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
              Expanded(
                flex: columns[3].flex,
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              Expanded(
                flex: columns[4].flex,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(active: problem.isActive),
                ),
              ),
              Expanded(
                flex: columns[5].flex,
                child: Text(
                  '$ideaCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: columns[6].flex,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _TableIconButton(
                        tooltip: 'Open problem',
                        icon: Icons.open_in_new_rounded,
                        onPressed: onOpenProblem,
                      ),
                      if (canSubmitIdea && problem.isActive) ...<Widget>[
                        const SizedBox(width: 4),
                        _TableIconButton(
                          tooltip: 'Submit idea',
                          icon: AppIcons.ideas,
                          color: const Color(0xFF6A38FF),
                          onPressed: onSubmitIdea,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? const Color(0xFF059669) : const Color(0xFF64748B);
    final Color bg = active ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _TableIconButton extends StatelessWidget {
  const _TableIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 17, color: color ?? const Color(0xFF475569)),
        ),
      ),
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState({required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(28),
        decoration: kDashboardCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.problems, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No problem statements found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onClearSearch, child: const Text('Clear search')),
          ],
        ),
      ),
    );
  }
}
