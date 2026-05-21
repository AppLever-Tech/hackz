import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../models/problem_list_config.dart';
import '../../models/problem_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/problem_query_service.dart';
import '../../widgets/problem_card.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';
import '../../widgets/faculty/submit_idea_dialog.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../workspace/workspace.dart';
import '../collegeadmin/problem_create_screen.dart';
import 'app_dialog_template.dart';
import 'dashboard_components.dart';

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
    _searchController.addListener(_onSearchChanged);
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
    final created = await showAppDialog<bool>(
      context: context,
      width: DialogWidthPreset.wide,
      child: SubmitIdeaDialog(
        currentUser: widget.currentUser,
        initialProblem: problem,
      ),
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
      return ProblemCreateScreen(
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
              ideaCountByProblemId: const <String, int>{},
            );
        final problems = result.items;
        _lastLoaded = problems;
        _metrics = result.metrics;

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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProblemCard(
                      key: ValueKey(problem.problemId),
                      problem: problem,
                      onOpenProblem: () => WorkspaceNavigator.openProblem(context, problem.problemId),
                      showSubmitIdea: widget.config.canSubmitIdea && problem.isActive,
                      onSubmitIdea: widget.config.canSubmitIdea && problem.isActive
                          ? () => _openSubmitIdea(problem)
                          : null,
                      canEdit: canEditProblem,
                      canDelete: widget.config.canToggleActive,
                      onEdit: canEditProblem ? _openEditProblem : null,
                      onDelete: widget.config.canToggleActive ? _deleteProblem : null,
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
                _buildMetricsRow(_metrics),
                const SizedBox(height: 12),
                _buildToolbar(context),
                const SizedBox(height: 12),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildFiltersPanel(allDepartments: allDepartments, allTags: allTags),
                  crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
                if (_hasAnyActiveFilter) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildActiveFiltersRow(),
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

  Widget _buildMetricsRow(ProblemDashboardMetrics metrics) {
    return ResponsiveMetricGrid(
      spacing: 10,
      runSpacing: 10,
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Problems',
          value: '${metrics.total}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.problems,
        ),
        DashboardMetricChipData.single(
          label: 'My Department',
          value: '${metrics.myDepartment}',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.departments,
        ),
        DashboardMetricChipData.single(
          label: 'With Ideas',
          value: '${metrics.withIdeas}',
          color: const Color(0xFF059669),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Without Ideas',
          value: '${metrics.withoutIdeas}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.submissions,
        ),
      ],
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

  Widget _buildToolbar(BuildContext context) {
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

    if (ResponsiveHelper.isMobile(context)) {
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

  Widget _buildFiltersPanel({
    required List<String> allDepartments,
    required List<String> allTags,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration.copyWith(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.config.enabledFilters.contains(ProblemFilterType.department)) ...<Widget>[
            const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allDepartments
                  .map(
                    (d) => FilterChip(
                      label: Text(d),
                      selected: _departmentFilters.contains(d),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _departmentFilters.add(d);
                          } else {
                            _departmentFilters.remove(d);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(ProblemFilterType.status)) ...<Widget>[
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _statusFilter == true,
                  onSelected: (_) => setState(() => _statusFilter = _statusFilter == true ? null : true),
                ),
                ChoiceChip(
                  label: const Text('Inactive'),
                  selected: _statusFilter == false,
                  onSelected: (_) => setState(() => _statusFilter = _statusFilter == false ? null : false),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(ProblemFilterType.tags)) ...<Widget>[
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags
                  .map(
                    (tag) => FilterChip(
                      label: Text(tag),
                      selected: _tagFilters.contains(tag),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _tagFilters.add(tag);
                          } else {
                            _tagFilters.remove(tag);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.config.enabledFilters.contains(ProblemFilterType.attachments)) ...<Widget>[
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('With Attachments'),
                  selected: _hasAttachments == true,
                  onSelected: (_) => setState(
                    () => _hasAttachments = _hasAttachments == true ? null : true,
                  ),
                ),
                ChoiceChip(
                  label: const Text('Without Attachments'),
                  selected: _hasAttachments == false,
                  onSelected: (_) => setState(
                    () => _hasAttachments = _hasAttachments == false ? null : false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: _clearAllFilters, child: const Text('Clear All')),
              const SizedBox(width: 6),
              FilledButton(onPressed: _loadProblems, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ..._departmentFilters.map(
          (d) => InputChip(
            label: Text(d),
            onDeleted: () {
              setState(() => _departmentFilters.remove(d));
              _loadProblems();
            },
          ),
        ),
        ..._tagFilters.map(
          (t) => InputChip(
            label: Text(t),
            onDeleted: () {
              setState(() => _tagFilters.remove(t));
              _loadProblems();
            },
          ),
        ),
        if (_statusFilter != null)
          InputChip(
            label: Text(_statusFilter == true ? 'Active' : 'Inactive'),
            onDeleted: () {
              setState(() => _statusFilter = null);
              _loadProblems();
            },
          ),
        if (_hasAttachments != null)
          InputChip(
            label: Text(_hasAttachments == true ? 'With Attachments' : 'Without Attachments'),
            onDeleted: () {
              setState(() => _hasAttachments = null);
              _loadProblems();
            },
          ),
      ],
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
