import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/user_model.dart';
import '../../../../responsive/responsive_helper.dart';
import '../../../../shared/feedback/feedback.dart';
import '../../../../screens/common/dashboard_chrome_scope.dart';
import '../../../../screens/common/dashboard_components.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../widgets/data_view/data_table_view.dart';
import '../../../idea/screens/innovation_submission_workspace.dart';
import '../../../../widgets/problem_table_columns.dart';
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
import '../authoring/problem_authoring_workspace.dart';
import 'problem_statement_details_pane.dart';
import '../../../evaluations/workspaces/evaluation_assignment_details_pane.dart';

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

  void _openAssignJudge(ProblemModel problem) {
    showEvaluationAssignmentPane(
      context,
      user: widget.currentUser,
      problemId: problem.problemId,
      backTooltip: 'Back to Problems',
    );
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

            final tableBody = problems.isEmpty
                ? _EmptyTableState(onClearSearch: () {
                    _searchController.clear();
                    _loadProblems();
                  })
                : DataTableView<ProblemModel>(
                    items: problems,
                    columns: ProblemTableColumns.build(
                      config: widget.config,
                      actions: _problemTableActions(),
                    ),
                    onSort: _onTableSort,
                    activeSortKey: _activeSortKey,
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
      ],
    );
  }

  ProblemTableActions _problemTableActions() {
    return ProblemTableActions(
      config: widget.config,
      ideaCountByProblemId: _ideaCountByProblemId,
      orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
      canEditFor: _canEditProblem,
      onOpenProblem: (ProblemModel problem) =>
          WorkspaceNavigator.openProblem(context, problem.problemId),
      onOpenDetails: _openDetails,
      onSubmitIdea: _openSubmitIdea,
      onAssignJudge: _openAssignJudge,
      onEditProblem: _openEditProblem,
      onDeleteProblem: _deleteProblem,
    );
  }

  /// `_sort` is the single source of truth — table headers mutate it here.
  String? get _activeSortKey {
    switch (_sort) {
      case ProblemSortType.newest:
      case ProblemSortType.oldest:
        return 'newest';
      case ProblemSortType.psNumber:
        return 'psNumber';
      case ProblemSortType.titleAZ:
        return 'title';
      case ProblemSortType.department:
        return 'department';
      case ProblemSortType.category:
        return 'category';
      case ProblemSortType.ideasCount:
        return 'ideas';
      case ProblemSortType.deadline:
        return 'deadline';
    }
  }

  void _onTableSort(String sortKey) {
    ProblemSortType? next;
    switch (sortKey) {
      case 'newest':
        next = _sort == ProblemSortType.newest
            ? ProblemSortType.oldest
            : ProblemSortType.newest;
        break;
      case 'psNumber':
        next = ProblemSortType.psNumber;
        break;
      case 'title':
        next = ProblemSortType.titleAZ;
        break;
      case 'department':
        next = ProblemSortType.department;
        break;
      case 'category':
        next = ProblemSortType.category;
        break;
      case 'ideas':
        next = ProblemSortType.ideasCount;
        break;
      case 'deadline':
        next = ProblemSortType.deadline;
        break;
    }
    if (next == null) return;
    if (!widget.config.enabledSorts.contains(next)) return;
    if (next == _sort) return;
    setState(() => _sort = next!);
    _loadProblems();
  }

  ButtonStyle _outlinedToolbarStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: const Color(0xFFFCFDFF),
        side: const BorderSide(color: Color(0xFFD9E2F5), width: 1.2),
      );
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
