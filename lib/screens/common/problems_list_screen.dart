import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/problem_list_config.dart';
import '../../models/idea_model.dart';
import '../../models/problem_model.dart';
import '../../models/attachment_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/problem_query_service.dart';
import '../../widgets/problem_card.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';
import '../../widgets/responsive/responsive_filter_bar.dart';
import '../../widgets/responsive/responsive_list_detail_layout.dart';
import '../collegeadmin/problem_create_screen.dart';
import 'app_dialog_template.dart';
import 'dashboard_components.dart';
import 'problem_detail_screen.dart';

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

  Future<List<ProblemModel>>? _problemsFuture;
  List<ProblemModel> _lastLoaded = <ProblemModel>[];

  bool _showFilters = false;
  bool? _statusFilter;
  bool? _hasAttachments;
  Set<String> _departmentFilters = <String>{};
  Set<String> _tagFilters = <String>{};
  ProblemSortType _sort = ProblemSortType.newest;
  ProblemModel? _selectedProblem;
  Map<String, _ProblemStats> _statsByProblemId = <String, _ProblemStats>{};
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
    _loadProblemStats();
  }

  Future<void> _loadProblemStats() async {
    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzIdeas)
          .where('orgId', isEqualTo: widget.config.orgId)
          .get(),
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzAttachments)
          .where('orgId', isEqualTo: widget.config.orgId)
          .where('entityType', isEqualTo: AttachmentEntityType.problem.value)
          .where('isActive', isEqualTo: true)
          .get(),
    ]);
    final snapshot = results[0];
    final attachmentSnapshot = results[1];
    final map = <String, _ProblemStats>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final problemId = ((data['problemId'] as String?) ?? '').trim();
      if (problemId.isEmpty) continue;
      final status = IdeaStatus.fromRaw((data['status'] as String?) ?? '');
      final current = map[problemId] ?? const _ProblemStats();
      map[problemId] = _ProblemStats(
        totalIdeas: current.totalIdeas + 1,
        evaluated: current.evaluated + (status == IdeaStatus.evaluated ? 1 : 0),
        approved: current.approved + (status == IdeaStatus.approved ? 1 : 0),
        attachments: current.attachments,
      );
    }
    for (final doc in attachmentSnapshot.docs) {
      final data = doc.data();
      final problemId = ((data['entityId'] as String?) ?? '').trim();
      if (problemId.isEmpty) continue;
      final current = map[problemId] ?? const _ProblemStats();
      map[problemId] = _ProblemStats(
        totalIdeas: current.totalIdeas,
        evaluated: current.evaluated,
        approved: current.approved,
        attachments: current.attachments + 1,
      );
    }
    if (!mounted) return;
    setState(() => _statsByProblemId = map);
  }

  Future<void> _openCreateProblem() async {
    setState(() {
      _showCreateProblem = true;
      _editingProblem = null;
      _selectedProblem = null;
    });
  }

  Future<void> _openEditProblem(ProblemModel problem) async {
    setState(() {
      _editingProblem = problem;
      _showCreateProblem = false;
      _selectedProblem = null;
    });
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

  Future<void> _showAttachments(ProblemModel problem) async {
    final attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.problem,
      entityId: problem.problemId,
    );
    if (attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attachments available for this problem.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(attachment.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(attachment.downloadUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          },
        );
      },
    );
  }

  Future<void> _openProblemDetails(ProblemModel problem) async {
    setState(() {
      _selectedProblem = problem;
      _showCreateProblem = false;
      _editingProblem = null;
    });
  }

  void _closeProblemDetails() {
    setState(() => _selectedProblem = null);
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
    return FutureBuilder<List<ProblemModel>>(
      future: _problemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load problems: ${snapshot.error}');
        }
        final problems = snapshot.data ?? _lastLoaded;
        _lastLoaded = problems;
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
                  final stats = _statsByProblemId[problem.problemId] ?? const _ProblemStats();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProblemCard(
                      key: ValueKey(problem.problemId),
                      problem: problem,
                      canEdit: canEditProblem,
                      canDelete: widget.config.canToggleActive,
                      onDelete: widget.config.canToggleActive ? _deleteProblem : null,
                      onEdit: canEditProblem ? _openEditProblem : null,
                      onViewAttachments: _showAttachments,
                      onViewDetails: _openProblemDetails,
                      totalIdeas: stats.totalIdeas,
                      evaluatedCount: stats.evaluated,
                      approvedCount: stats.approved,
                      attachmentCount: stats.attachments,
                    ),
                  );
                },
              );
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final listPanel = SectionContainer(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(count: problems.length),
                  const SizedBox(height: 6),
                  ResponsiveSearchFilterBar(
                    searchController: _searchController,
                    searchHint: 'Search by title, tags, problem number',
                    filtersExpanded: _showFilters,
                    onToggleFilters: () => setState(() => _showFilters = !_showFilters),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildFiltersPanel(allDepartments: allDepartments, allTags: allTags),
                    crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                  if (_hasAnyActiveFilter) ...<Widget>[
                    const SizedBox(height: 8),
                    _buildActiveFiltersRow(),
                  ],
                  const SizedBox(height: 8),
                  if (hasBoundedHeight)
                    Expanded(child: listWidget)
                  else
                    SizedBox(height: 420, child: listWidget),
                ],
              ),
            );

            final selected = _selectedProblem;
            return ResponsiveListDetailLayout(
              hasSelection: selected != null,
              onCloseDetail: _closeProblemDetails,
              backLabel: 'Back to Problems',
              list: listPanel,
              detail: selected == null
                  ? const SizedBox.shrink()
                  : ProblemDetailScreen(
                      problem: selected,
                      currentUser: widget.currentUser,
                      embedded: true,
                      onBack: _closeProblemDetails,
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader({required int count}) {
    return ResponsiveWrapToolbar(
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        if (widget.config.canCreate)
          FilledButton.icon(
            onPressed: _openCreateProblem,
            icon: const Icon(AppIcons.add),
            label: const Text('Add Problem'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Sort', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProblemSortType>(
                  value: _sort,
                  isDense: true,
                  borderRadius: BorderRadius.circular(14),
                  items: _availableSorts
                      .map(
                        (sort) => DropdownMenuItem<ProblemSortType>(
                          value: sort,
                          child: Text(_sortLabel(sort)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    _loadProblems();
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Showing $count Problems', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersPanel({
    required List<String> allDepartments,
    required List<String> allTags,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
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

  Widget _buildSortAndCountBar(int count) {
    const order = <ProblemSortType>[
      ProblemSortType.newest,
      ProblemSortType.oldest,
      ProblemSortType.titleAZ,
      ProblemSortType.department,
    ];
    final availableSorts =
        order.where((sort) => widget.config.enabledSorts.contains(sort)).toList(growable: false);
    return Row(
      children: <Widget>[
        Text(
          '$count Problems',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const Text('Sort:'),
        const SizedBox(width: 8),
        DropdownButton<ProblemSortType>(
          value: _sort,
          items: availableSorts
              .map(
                (sort) => DropdownMenuItem<ProblemSortType>(
                  value: sort,
                  child: Text(_sortLabel(sort)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _sort = value);
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

class _ProblemStats {
  const _ProblemStats({
    this.totalIdeas = 0,
    this.evaluated = 0,
    this.approved = 0,
    this.attachments = 0,
  });

  final int totalIdeas;
  final int evaluated;
  final int approved;
  final int attachments;
}
