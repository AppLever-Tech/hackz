import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../../../models/attachment_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/user_model.dart';
import '../../../../responsive/responsive_helper.dart';
import '../../../../shared/feedback/feedback.dart';
import '../../../../screens/common/dashboard_chrome_scope.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../../../utils/attachment_service.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../widgets/common/card_overflow_menu.dart';
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
import '../../widgets/problem_workflow_action_pill.dart';
import '../authoring/problem_authoring_workspace.dart';
import 'problem_statement_details_pane.dart';

/// Fixed gap inserted between the PS # cell and the Title cell so the
/// compact problem context pill doesn't visually butt up against the
/// adjacent problem title. Used by both the header and data rows so column
/// alignment stays pixel-perfect.
const double _kPsTitleGap = 12;
const double _kDeptCategoryGap = 12;

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

  // Filter state. Defaults to "no filter" (i.e. show everything). The same
  // [ProblemFiltersPanel] / [ProblemActiveFiltersRow] widgets drive both
  // this screen and the dashboard cards layout.
  bool _showFilters = false;
  bool? _statusFilter;
  bool? _hasAttachments;
  Set<String> _departmentFilters = <String>{};
  Set<String> _tagFilters = <String>{};

  // Embedded authoring workspace toggles. When either is set, the table is
  // replaced in-place by [ProblemAuthoringWorkspace] (create or edit mode).
  ProblemModel? _editingProblem;
  bool _showCreateProblem = false;

  // Column flexes/min-widths are tuned for desktop (~1024+) but the screen
  // wraps the table in a horizontal Scrollbar when the available width is
  // smaller than the sum of [minWidth]s — so mobile gets a usable
  // side-scroll without a separate code path.
  static const List<_TableColumn> _columns = <_TableColumn>[
    _TableColumn(label: 'PS #', flex: 3, minWidth: 132),
    _TableColumn(label: 'Title', flex: 10, minWidth: 220),
    _TableColumn(label: 'Department', flex: 3, minWidth: 120),
    _TableColumn(label: 'Category', flex: 2, minWidth: 76),
    _TableColumn(label: 'Theme', flex: 3, minWidth: 96),
    _TableColumn(label: 'Ideas', flex: 2, minWidth: 76, align: TextAlign.center),
    _TableColumn(label: 'Deadline', flex: 2, minWidth: 92, align: TextAlign.center),
    _TableColumn(label: 'Actions', flex: 3, minWidth: 180, align: TextAlign.end),
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

  Future<void> _openCreateProblem() async {
    setState(() {
      _showCreateProblem = true;
      _editingProblem = null;
    });
  }

  Future<void> _openEditProblem(ProblemModel problem) async {
    setState(() {
      _editingProblem = problem;
      _showCreateProblem = false;
    });
  }

  void _closeProblemForm() {
    setState(() {
      _showCreateProblem = false;
      _editingProblem = null;
    });
  }

  Future<void> _onProblemFormSaved() async {
    _closeProblemForm();
    _loadProblems();
  }

  /// Department admins may only edit problems they personally authored;
  /// college admin and sys admin retain blanket edit rights gated by
  /// [ProblemListConfig.canEdit].
  bool _canEditProblem(ProblemModel problem) {
    if (!widget.config.canEdit) return false;
    final role = UserRole.fromCode(widget.currentUser.role);
    if (role == UserRole.departmentAdmin) {
      return problem.createdBy.trim() == widget.currentUser.userId.trim();
    }
    return true;
  }

  Future<void> _deleteProblem(ProblemModel problem) async {
    final bool shouldDelete = await FeedbackService.showConfirmation(
      context,
      title: 'Delete Problem',
      message: 'Delete this problem permanently?',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!shouldDelete) return;
    await AttachmentService.deactivateEntityAttachments(
      entityType: AttachmentEntityType.problem,
      entityId: problem.problemId,
    );
    await FirestoreUtils.deleteProblem(problem.problemId);
    if (!mounted) return;
    _loadProblems();
  }

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
    if (_showCreateProblem || _editingProblem != null) {
      return ProblemAuthoringWorkspace(
        currentUser: widget.currentUser,
        initialProblem: _editingProblem,
        embedded: true,
        onBack: _closeProblemForm,
        onSaved: _onProblemFormSaved,
      );
    }
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
            final tableMinWidth =
                _columns.fold<double>(0, (sum, c) => sum + c.minWidth) + 32 + _kPsTitleGap + _kDeptCategoryGap;

            final tableBody = problems.isEmpty
                ? _EmptyTableState(onClearSearch: () {
                    _searchController.clear();
                    _loadProblems();
                  })
                : _ProblemStatementsTable(
                    problems: problems,
                    ideaCountByProblemId: _ideaCountByProblemId,
                    orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
                    columns: _columns,
                    minWidth: tableMinWidth,
                    canSubmitIdea: widget.config.canSubmitIdea,
                    canDelete: widget.config.canToggleActive,
                    canEditFor: _canEditProblem,
                    onOpenProblem: (problem) => WorkspaceNavigator.openProblem(context, problem.problemId),
                    onOpenDetails: _openDetails,
                    onSubmitIdea: _openSubmitIdea,
                    onEditProblem: _openEditProblem,
                    onDeleteProblem: _deleteProblem,
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

    final Widget? createButton = widget.config.canCreate
        ? FilledButton.icon(
            onPressed: _openCreateProblem,
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Create Problem'),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, mobile ? 40 : 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : null;

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          searchField,
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (createButton != null) createButton,
              filterButton,
              sortButton,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (createButton != null) ...<Widget>[
          createButton,
          const SizedBox(width: 8),
        ],
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
      case ProblemSortType.category:
        return 'Category';
      case ProblemSortType.psNumber:
        return 'PS #';
      case ProblemSortType.ideasCount:
        return 'Ideas submitted';
      case ProblemSortType.deadline:
        return 'Deadline (soonest)';
    }
  }

  List<ProblemSortType> get _availableSorts {
    // Order surfaced in the dropdown — recency first, then the column-aligned
    // sorts (PS #, Title, Department, Category, Ideas, Deadline) so the menu
    // reads top-to-bottom like the table reads left-to-right.
    const order = <ProblemSortType>[
      ProblemSortType.newest,
      ProblemSortType.oldest,
      ProblemSortType.psNumber,
      ProblemSortType.titleAZ,
      ProblemSortType.department,
      ProblemSortType.category,
      ProblemSortType.ideasCount,
      ProblemSortType.deadline,
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
    required this.orgDefaultMaxIdeas,
    required this.columns,
    required this.minWidth,
    required this.canSubmitIdea,
    required this.canDelete,
    required this.canEditFor,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
    required this.onEditProblem,
    required this.onDeleteProblem,
  });

  final List<ProblemModel> problems;
  final Map<String, int> ideaCountByProblemId;
  final int orgDefaultMaxIdeas;
  final List<_TableColumn> columns;
  final double minWidth;
  final bool canSubmitIdea;
  final bool canDelete;
  final bool Function(ProblemModel problem) canEditFor;
  final ValueChanged<ProblemModel> onOpenProblem;
  final ValueChanged<ProblemModel> onOpenDetails;
  final ValueChanged<ProblemModel> onSubmitIdea;
  final ValueChanged<ProblemModel> onEditProblem;
  final ValueChanged<ProblemModel> onDeleteProblem;

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
                      final bool canEdit = canEditFor(problem);
                      final IdeaSubmissionGate gate = computeIdeaSubmissionGate(
                        problem: problem,
                        submittedCount: ideaCountByProblemId[problem.problemId] ?? 0,
                        orgDefaultMaxIdeas: orgDefaultMaxIdeas,
                      );
                      return _TableDataRow(
                        problem: problem,
                        columns: columns,
                        striped: index.isOdd,
                        gate: gate,
                        canSubmitIdea: canSubmitIdea,
                        canEdit: canEdit,
                        canDelete: canDelete,
                        onOpenProblem: () => onOpenProblem(problem),
                        onOpenDetails: () => onOpenDetails(problem),
                        onSubmitIdea: () => onSubmitIdea(problem),
                        onEdit: canEdit ? () => onEditProblem(problem) : null,
                        onDelete: canDelete ? () => onDeleteProblem(problem) : null,
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
        children: <Widget>[
          for (int i = 0; i < columns.length; i++) ...<Widget>[
            // Mirror the 12 px PS # / Title gap used in [_TableDataRow] so
            // header labels stay aligned over their cells.
            if (i == 1) const SizedBox(width: _kPsTitleGap),
            if (i == 3) const SizedBox(width: _kDeptCategoryGap),
            Expanded(
              flex: columns[i].flex,
              child: Text(
                columns[i].label.toUpperCase(),
                textAlign: columns[i].align,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableDataRow extends StatelessWidget {
  const _TableDataRow({
    required this.problem,
    required this.columns,
    required this.striped,
    required this.gate,
    required this.canSubmitIdea,
    required this.canEdit,
    required this.canDelete,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
    required this.onEdit,
    required this.onDelete,
  });

  final ProblemModel problem;
  final List<_TableColumn> columns;
  final bool striped;
  final IdeaSubmissionGate gate;
  final bool canSubmitIdea;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onOpenProblem;
  final VoidCallback onOpenDetails;
  final VoidCallback onSubmitIdea;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String number =
        problem.problemNumber.trim().isEmpty ? '—' : problem.problemNumber.trim();
    final String title = problem.title.trim().isEmpty ? 'Untitled' : problem.title.trim();
    final String department = problem.departmentDisplayName.trim().isEmpty
        ? '—'
        : problem.departmentDisplayName.trim();
    final String category =
        problem.category.trim().isEmpty ? '—' : problem.category.trim();
    final String theme = problem.theme.trim().isEmpty ? '—' : problem.theme.trim();
    final String ideasLabel = '${gate.submittedCount}/${gate.effectiveMaxIdeas}';

    // Two-line deadline: day-month on the first line, year on the second.
    // Keeps the column narrow while still rendering the full date.
    String deadlineDayMonth = '—';
    String deadlineYear = '';
    if (problem.ideaSubmissionDeadline != null) {
      final DateTime d = problem.ideaSubmissionDeadline!;
      deadlineDayMonth = '${d.day} ${kMonthNames[d.month - 1]}';
      deadlineYear = '${d.year}';
    }

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
            // PS # — active status dot precedes the problem context pill so
            // the row's status is the first thing a scanning eye lands on.
            Expanded(
              flex: columns[0].flex,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _ActiveStatusDot(active: problem.isActive),
                  const SizedBox(width: 6),
                  Flexible(
                    child: ContextPill(
                      label: number,
                      semantic: ContextPillSemantic.problem,
                      onTap: onOpenProblem,
                      compact: true,
                      fitContent: true,
                    ),
                  ),
                ],
              ),
            ),
            // Visual breathing room between the PS # pill and the problem
            // title so adjacent rows don't read like a single run-on cell.
            const SizedBox(width: _kPsTitleGap),
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
            const SizedBox(width: _kDeptCategoryGap),
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
              // Theme wraps freely to additional lines instead of being
              // truncated — most theme strings fit on one line but long
              // labels like "Sustainability & Climate" are preserved.
              child: Text(
                theme,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ),
            Expanded(
              flex: columns[5].flex,
              child: Text(
                ideasLabel,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    deadlineDayMonth,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.2,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  if (deadlineYear.isNotEmpty)
                    Text(
                      deadlineYear,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.2,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: columns[7].flex,
              child: Align(
                alignment: Alignment.centerRight,
                child: _ProblemRowActionArea(
                  problem: problem,
                  gate: gate,
                  canSubmitIdea: canSubmitIdea,
                  canEdit: canEdit,
                  canDelete: canDelete,
                  onSubmitIdea: onSubmitIdea,
                  onOpenDetails: onOpenDetails,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid 8-px dot used as the inline active-status indicator next to the
/// problem context pill (replacing the dedicated Status column).
class _ActiveStatusDot extends StatelessWidget {
  const _ActiveStatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color dot = active ? const Color(0xFF059669) : const Color(0xFFCBD5E1);
    return Tooltip(
      message: active ? 'Active' : 'Inactive',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
    );
  }
}

/// Row-level ⋮ overflow menu — reuses [CardOverflowMenuButton] from the
/// shared widgets pack so the popup styling is identical to the faculty
/// teams card and judge cards.
///
/// Action order for users who can submit ideas (faculty, student) places
/// **Submit Idea** first; everyone else sees the workspace / details /
/// authoring actions in order. Destructive Delete is always last with a
/// divider above it.
class _ProblemRowActionArea extends StatelessWidget {
  const _ProblemRowActionArea({
    required this.problem,
    required this.gate,
    required this.canSubmitIdea,
    required this.canEdit,
    required this.canDelete,
    required this.onSubmitIdea,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final ProblemModel problem;
  final IdeaSubmissionGate gate;
  final bool canSubmitIdea;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onSubmitIdea;
  final VoidCallback onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool showSubmit = canSubmitIdea;
    final bool submitEnabled = showSubmit && problem.isActive && gate.canSubmit;
    final bool isClosed = showSubmit && !submitEnabled;
    final List<CardOverflowMenuAction> actions = <CardOverflowMenuAction>[
      const CardOverflowMenuAction(
        value: 'details',
        icon: AppIcons.preview,
        label: 'View Details',
      ),
      if (canEdit && onEdit != null)
        const CardOverflowMenuAction(
          value: 'edit',
          icon: AppIcons.edit,
          label: 'Edit Problem',
        ),
      if (canDelete && onDelete != null)
        const CardOverflowMenuAction(
          value: 'delete',
          icon: AppIcons.remove,
          label: 'Delete Problem',
          danger: true,
        ),
    ];

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ResponsiveHelper.isMobile(context) ? 4 : 6,
      runSpacing: 4,
      children: <Widget>[
        if (showSubmit && submitEnabled)
          ProblemWorkflowActionPill(
            label: 'Idea',
            showPlusPrefix: true,
            contentIcon: AppIcons.ideas,
            semantic: ProblemWorkflowPillSemantic.filledBrand,
            onTap: onSubmitIdea,
            tooltip: 'Submit idea',
          ),
        if (isClosed)
          const ProblemWorkflowActionPill(
            label: 'Closed',
            icon: AppIcons.statusInactive,
            semantic: ProblemWorkflowPillSemantic.closed,
            enabled: false,
            tooltip: 'Submissions closed',
          ),
        CardOverflowMenuButton(
          tooltip: 'Problem actions',
          dividersBefore: const <String>{'delete'},
          actions: actions,
          onSelected: (String value) {
            switch (value) {
              case 'details':
                onOpenDetails();
              case 'edit':
                onEdit?.call();
              case 'delete':
                onDelete?.call();
            }
          },
        ),
      ],
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
