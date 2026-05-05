import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/problem_list_config.dart';
import '../../models/problem_model.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/problem_query_service.dart';
import '../../widgets/problem_card.dart';
import '../collegeadmin/problem_create_screen.dart';
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
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProblemCreateScreen(currentUser: widget.currentUser),
      ),
    );
    if (created == true && mounted) {
      _loadProblems();
    }
  }

  Future<void> _openEditProblem(ProblemModel problem) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProblemCreateScreen(
          currentUser: widget.currentUser,
          initialProblem: problem,
        ),
      ),
    );
    if (updated == true && mounted) {
      _loadProblems();
    }
  }

  bool _canEditProblem(ProblemModel problem) {
    if (!widget.config.canEdit) return false;
    final role = UserRole.fromCode(widget.currentUser.role);
    if (role == UserRole.departmentAdmin) {
      return problem.createdBy.trim() == widget.currentUser.userId.trim();
    }
    return true;
  }

  Future<void> _toggleProblemActive(ProblemModel problem) async {
    await FirestoreUtils.updateProblem(
      problem.problemId,
      <String, dynamic>{'isActive': !problem.isActive},
    );
    if (!mounted) return;
    _loadProblems();
  }

  Future<void> _showAttachments(ProblemModel problem) async {
    if (problem.attachments.isEmpty) {
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
          itemCount: problem.attachments.length,
          itemBuilder: (context, index) {
            final url = problem.attachments[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          },
        );
      },
    );
  }

  Future<void> _openProblemDetails(ProblemModel problem) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProblemDetailScreen(
          problem: problem,
          currentUser: widget.currentUser,
        ),
      ),
    );
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProblemCard(
                      key: ValueKey(problem.problemId),
                      problem: problem,
                      canEdit: canEditProblem,
                      canToggleActive: widget.config.canToggleActive,
                      onToggleActive: widget.config.canToggleActive ? _toggleProblemActive : null,
                      onEdit: canEditProblem ? _openEditProblem : null,
                      onViewAttachments: _showAttachments,
                      onViewDetails: _openProblemDetails,
                    ),
                  );
                },
              );
        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            return SectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSearchAndFilterRow(),
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
                  _buildSortAndCountBar(problems.length),
                  const SizedBox(height: 12),
                  if (hasBoundedHeight)
                    Expanded(child: listWidget)
                  else
                    SizedBox(height: 420, child: listWidget),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Problems',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.config.canCreate)
          FilledButton.icon(
            onPressed: _openCreateProblem,
            icon: const Icon(Icons.add),
            label: const Text('Add Problem'),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title, tags, problem number',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: const Icon(Icons.tune),
          label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
}
