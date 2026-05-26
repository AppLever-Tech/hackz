import 'dart:async';

import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/attachment_model.dart';
import '../../../models/enums/user_role.dart';
import '../../../models/user_model.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../screens/common/app_dialog_template.dart';
import '../../../utils/attachment_service.dart';
import '../../../utils/firestore_utils.dart';
import '../../../widgets/faculty/innovation_submission_workspace.dart';
import '../../../widgets/responsive/responsive_alert_dialog.dart';
import '../../../workspace/workspace.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../models/problem_list_config.dart';
import '../models/problem_model.dart';
import '../services/problem_query_service.dart';
import '../validators/problem_submission_validators.dart';
import '../widgets/problem_card.dart';
import '../widgets/problem_filters_panel.dart';
import '../widgets/problem_metrics_row.dart';
import 'authoring/problem_authoring_workspace.dart';

class ProblemsListScreen extends StatefulWidget {
  const ProblemsListScreen({
    super.key,
    required this.currentUser,
    required this.config,
  });

  final UserModel currentUser;
  final ProblemListConfig config;

  @override
  State<ProblemsListScreen> createState() => _ProblemsListScreenState();
}

class _ProblemsListScreenState extends State<ProblemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<ProblemListQueryResult>? _problemsFuture;
  List<ProblemModel> _lastLoaded = <ProblemModel>[];
  ProblemDashboardMetrics _metrics = ProblemDashboardMetrics.empty;
  Map<String, int> _ideaCountByProblemId = <String, int>{};
  int _orgDefaultMaxIdeas = 50;

  bool _showFilters = false;
  bool? _statusFilter;
  bool? _hasAttachments;
  Set<String> _departmentFilters = <String>{};
  Set<String> _tagFilters = <String>{};
  ProblemSortType _sort = ProblemSortType.newest;
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

  /// Reads the org-scoped default-max-ideas setting so the per-problem
  /// submission gate can fall back to it when a problem doesn't specify its
  /// own cap. The widget keeps the previous value if the load fails so the
  /// list stays interactive.
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
      // Default of 50 already applied; leave silent.
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

  bool _canEditProblem(ProblemModel problem) {
    if (!widget.config.canEdit) return false;
    final role = UserRole.fromCode(widget.currentUser.role);
    if (role == UserRole.departmentAdmin) {
      return problem.createdBy.trim() == widget.currentUser.userId.trim();
    }
    return true;
  }

  Future<void> _deleteProblem(ProblemModel problem) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveAlertDialog(
        title: const Text('Delete Problem'),
        widthPreset: DialogWidthPreset.compact,
        content: const Text('Delete this problem permanently?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await AttachmentService.deactivateEntityAttachments(
      entityType: AttachmentEntityType.problem,
      entityId: problem.problemId,
    );
    await FirestoreUtils.deleteProblem(problem.problemId);
    if (!mounted) return;
    _loadProblems();
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

  void _clearAllFilters() {
    setState(() {
      _statusFilter = null;
      _hasAttachments = null;
      _departmentFilters = <String>{};
      _tagFilters = <String>{};
    });
    _loadProblems();
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load problems: ${snapshot.error}');
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

        final listWidget = problems.isEmpty
            ? const Center(child: Text('No problems found for the selected criteria.'))
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: problems.length,
                itemBuilder: (context, index) {
                  final problem = problems[index];
                  final canEditProblem = _canEditProblem(problem);
                  final IdeaSubmissionGate gate = computeIdeaSubmissionGate(
                    problem: problem,
                    submittedCount: _ideaCountByProblemId[problem.problemId] ?? 0,
                    orgDefaultMaxIdeas: _orgDefaultMaxIdeas,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProblemCard(
                      key: ValueKey(problem.problemId),
                      problem: problem,
                      onOpenProblem: () => WorkspaceNavigator.openProblem(context, problem.problemId),
                      showSubmitIdea: widget.config.canSubmitIdea && problem.isActive,
                      // The card disables the Submit button itself when the
                      // gate is closed; keep the callback wired in all cases
                      // so the disabled label/state can be rendered correctly.
                      onSubmitIdea: widget.config.canSubmitIdea && problem.isActive
                          ? () => _openSubmitIdea(problem)
                          : null,
                      canEdit: canEditProblem,
                      canDelete: widget.config.canToggleActive,
                      onEdit: canEditProblem ? _openEditProblem : null,
                      onDelete: widget.config.canToggleActive ? _deleteProblem : null,
                      gate: gate,
                    ),
                  );
                },
              );

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ProblemMetricsRow(metrics: _metrics),
                const SizedBox(height: 12),
                _buildToolbar(context, maxWidth: constraints.maxWidth),
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
                  crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                const SizedBox(height: 12),
                if (hasBoundedHeight)
                  Expanded(child: listWidget)
                else
                  SizedBox(height: 420, child: listWidget),
              ],
            );
          },
        );
      },
    );
  }

  ButtonStyle _toolbarButtonStyle(BuildContext context) => OutlinedButton.styleFrom(
        minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: const Color(0xFFFCFDFF),
        side: const BorderSide(color: Color(0xFFD9E2F5), width: 1.2),
        disabledForegroundColor: const Color(0xFF334155),
        disabledBackgroundColor: const Color(0xFFFCFDFF),
      );

  Widget _buildToolbar(BuildContext context, {required double maxWidth}) {
    final bool useStackedToolbar =
        ResponsiveHelper.isMobile(context) || maxWidth < 768;
    final filterButton = OutlinedButton.icon(
      onPressed: () => setState(() => _showFilters = !_showFilters),
      icon: const Icon(Icons.tune),
      label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
      style: _toolbarButtonStyle(context),
    );

    final sortButton = _buildSortButton(context);

    final createButton = widget.config.canCreate
        ? FilledButton.icon(
            onPressed: _openCreateProblem,
            icon: const Icon(AppIcons.add, size: 18),
            label: const Text('Create Problem'),
            style: FilledButton.styleFrom(
              minimumSize: Size(0, ResponsiveHelper.isMobile(context) ? 40 : 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        : null;

    final searchField = TextField(
      controller: _searchController,
      onSubmitted: (_) => _loadProblems(),
      decoration: InputDecoration(
        hintText: 'Search by title, tags, problem number',
        prefixIcon: const Icon(AppIcons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: ResponsiveHelper.isMobile(context) ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    if (useStackedToolbar) {
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
          icon: const Icon(Icons.swap_vert),
          label: Text(_sortLabel(_sort)),
          style: _toolbarButtonStyle(context),
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

  bool get _hasAnyActiveFilter {
    return _departmentFilters.isNotEmpty ||
        _tagFilters.isNotEmpty ||
        _statusFilter != null ||
        _hasAttachments != null;
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
