import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/idea_list_config.dart';
import '../services/idea_status_helpers.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../user/models/user_model.dart';
import '../services/idea_query_service.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../widgets/idea_table_columns.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../widgets/idea_metrics_row.dart';
import 'idea_details_pane.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/empty_search_state.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

class IdeasListScreen extends StatefulWidget {
  const IdeasListScreen({
    super.key,
    required this.currentUser,
    required this.config,
  });

  final UserModel currentUser;
  final IdeaListConfig config;

  @override
  State<IdeasListScreen> createState() => _IdeasListScreenState();
}

class _IdeasListScreenState extends State<IdeasListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<IdeaListQueryResult>? _ideasFuture;
  List<IdeaListItem> _lastLoaded = <IdeaListItem>[];
  IdeaDepartmentMetrics _metrics = IdeaDepartmentMetrics.empty;

  bool _showFilters = false;
  Set<IdeaStatus> _statusFilters = <IdeaStatus>{};
  Set<String> _problemFilters = <String>{};
  Set<String> _departmentFilters = <String>{};
  IdeaSortType _sort = IdeaSortType.newest;

  @override
  void initState() {
    super.initState();
    _sort = widget.config.enabledSorts.contains(IdeaSortType.newest)
        ? IdeaSortType.newest
        : widget.config.enabledSorts.first;
    _loadIdeas();
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadIdeas);
  }

  void _loadIdeas() {
    setState(() {
      _ideasFuture = IdeaQueryService.fetchIdeas(
        IdeaQueryParams(
          config: widget.config,
          search: _searchController.text,
          sortType: _sort,
          statusFilters: _statusFilters,
          problemFilters: _problemFilters,
          departmentFilters: _departmentFilters,
          viewer: widget.currentUser,
        ),
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilters = <IdeaStatus>{};
      _problemFilters = <String>{};
      _departmentFilters = <String>{};
    });
    _loadIdeas();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.canViewIdeas) {
      return const Center(
        child: Text('Ideas are not available for your role.'),
      );
    }
    return FutureBuilder<IdeaListQueryResult>(
      future: _ideasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lastLoaded.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load ideas: ${snapshot.error}');
        }
        final IdeaListQueryResult result = snapshot.data ??
            IdeaListQueryResult(items: _lastLoaded, metrics: _metrics);
        final ideas = result.items;
        _lastLoaded = ideas;
        _metrics = result.metrics;
        final availableProblems = <String, String>{
          for (final item in ideas)
            if (item.idea.problemId.isNotEmpty)
              item.idea.problemId: item.idea.problemTitle.isEmpty
                  ? item.idea.problemId
                  : '${item.idea.problemNumber.isEmpty ? '' : '${item.idea.problemNumber} - '}${item.idea.problemTitle}',
        };
        final availableDepartments = ideas
            .map((e) => e.idea.teamDepartmentCode)
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

        final IdeaTableActions tableActions = _ideaTableActions();
        final List<IdeaListItem> displayItems = ideas;

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final bool mobile = ResponsiveHelper.isMobile(context);

            final Widget header = _buildListHeader(
              context: context,
              maxWidth: constraints.maxWidth,
              availableProblems: availableProblems,
              availableDepartments: availableDepartments,
            );

            final Widget contentWidget = displayItems.isEmpty
                ? EmptySearchState.ideas(
                    onClearSearch: () {
                      if (_searchController.text.trim().isEmpty) return;
                      _searchController.clear();
                      _loadIdeas();
                    },
                  )
                : mobile
                    ? ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: displayItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          return IdeaListRowCard(
                            item: displayItems[index],
                            config: widget.config,
                            actions: tableActions,
                          );
                        },
                      )
                    : DataTableView<IdeaListItem>(
                        items: displayItems,
                        columns: IdeaTableColumns.build(
                          config: widget.config,
                          actions: tableActions,
                        ),
                        onSort: _onTableSort,
                        activeSortKey: _activeSortKey,
                      );

            if (!hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  SizedBox(height: 420, child: contentWidget),
                ],
              );
            }

            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Expanded(child: contentWidget),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(child: contentWidget),
              ],
            );
          },
        );
      },
    );
  }

  void _openIdeaDetails(IdeaListItem item) {
    showIdeaDetailsPane(context, ideaId: item.idea.ideaId);
  }

  IdeaTableActions _ideaTableActions() {
    return IdeaTableActions(
      onOpenIdea: _openIdeaDetails,
      onOpenTeam: (IdeaListItem item) {
        final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
        if (teamId.isEmpty) return;
        WorkspaceNavigator.openTeam(context, teamId);
      },
      onOpenProblem: (IdeaListItem item) {
        final String problemId = item.idea.problemId.trim();
        if (problemId.isEmpty) return;
        WorkspaceNavigator.openProblem(context, problemId);
      },
      onOpenEvent: (IdeaListItem item, String eventId) {
        final String id = eventId.trim();
        if (id.isEmpty) return;
        WorkspaceNavigator.openIdeathon(context, id, actor: widget.currentUser);
      },
    );
  }

  /// `_sort` is the single source of truth — table headers mutate it here.
  String? get _activeSortKey {
    switch (_sort) {
      case IdeaSortType.newest:
      case IdeaSortType.oldest:
        return 'newest';
      case IdeaSortType.status:
        return null;
    }
  }

  void _onTableSort(String sortKey) {
    if (sortKey != 'newest') return;
    final IdeaSortType next =
        _sort == IdeaSortType.newest ? IdeaSortType.oldest : IdeaSortType.newest;
    if (!widget.config.enabledSorts.contains(next)) return;
    if (next == _sort) return;
    setState(() => _sort = next);
    _loadIdeas();
  }

  Widget _buildListHeader({
    required BuildContext context,
    required double maxWidth,
    required Map<String, String> availableProblems,
    required List<String> availableDepartments,
  }) {
    final bool compact = ResponsiveHelper.isMobile(context);

    final Widget metrics = IdeaMetricsRow(metrics: _metrics, spacing: compact ? 8 : 10, runSpacing: compact ? 8 : 10);
    final Widget searchBar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search by idea title, problem, or description',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      onSearchSubmitted: _loadIdeas,
      iconOnlyFilterOnMobile: true,
    );
    final Widget filters = AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: _buildFiltersPanel(
        context: context,
        availableProblems: availableProblems,
        availableDepartments: availableDepartments,
      ),
      crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
    );
    final Widget? activeFilters = _hasAnyActiveFilter ? _buildActiveFiltersRow(availableProblems) : null;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          metrics,
          const SizedBox(height: 8),
          searchBar,
          const SizedBox(height: 6),
          filters,
          if (activeFilters != null) ...<Widget>[
            const SizedBox(height: 6),
            activeFilters,
          ],
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        metrics,
        const SizedBox(height: 12),
        searchBar,
        const SizedBox(height: 12),
        filters,
        if (activeFilters != null) ...<Widget>[
          const SizedBox(height: 12),
          activeFilters,
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFiltersPanel({
    required BuildContext context,
    required Map<String, String> availableProblems,
    required List<String> availableDepartments,
  }) {
    final bool compact = MobileFilterPaneStyles.useCompact(context);
    final double sectionGap = MobileFilterPaneStyles.sectionGap(compact: compact);
    final double chipGap = MobileFilterPaneStyles.chipGap(compact: compact);
    final TextStyle sectionLabel = MobileFilterPaneStyles.sectionLabel(compact: compact);

    return MobileFilterPaneStyles.panelShell(
      compact: compact,
      decoration: kDashboardCardDecoration.copyWith(
        color: MobileFilterPaneStyles.panelColor,
        borderRadius: MobileFilterPaneStyles.panelBorderRadius(compact: compact),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.config.enabledFilters.contains(IdeaFilterType.status)) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.filter_alt_outlined, size: compact ? 16 : 18, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text('Status', style: sectionLabel),
              ],
            ),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: IdeaStatus.values
                  .map(
                    (status) => MobileFilterPaneStyles.filterChip(
                      compact: compact,
                      avatar: Icon(_statusIcon(status), size: compact ? 14 : 16),
                      label: _statusLabel(status),
                      selected: _statusFilters.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _statusFilters.add(status);
                          } else {
                            _statusFilters.remove(status);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            SizedBox(height: sectionGap),
          ],
          if (widget.config.enabledFilters.contains(IdeaFilterType.problem)) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(AppIcons.problems, size: compact ? 16 : 18, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text('Problem', style: sectionLabel),
              ],
            ),
            SizedBox(height: chipGap),
            DropdownButtonFormField<String>(
              value: _problemFilters.length == 1 ? _problemFilters.first : null,
              isExpanded: true,
              isDense: compact,
              items: availableProblems.entries
                  .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _problemFilters = value == null ? <String>{} : <String>{value};
              }),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: compact ? 8 : 12,
                ),
                prefixIcon: const Icon(AppIcons.problems),
                border: const OutlineInputBorder(),
                hintText: 'Select problem',
              ),
            ),
            SizedBox(height: sectionGap),
          ],
          if (widget.config.enabledFilters.contains(IdeaFilterType.department) &&
              widget.config.ideaDepartmentScope == IdeaDepartmentScope.none) ...<Widget>[
            Row(
              children: <Widget>[
                Icon(AppIcons.departments, size: compact ? 16 : 18, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text('Department', style: sectionLabel),
              ],
            ),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: availableDepartments
                  .map(
                    (d) => MobileFilterPaneStyles.filterChip(
                      compact: compact,
                      avatar: Icon(AppIcons.departments, size: compact ? 14 : 16),
                      label: d,
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
            SizedBox(height: sectionGap),
          ],
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: _clearAllFilters,
            onApply: _loadIdeas,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow(Map<String, String> problems) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ..._statusFilters.map(
          (status) => InputChip(
            avatar: Icon(_statusIcon(status), size: 16),
            label: Text(_statusLabel(status)),
            onDeleted: () {
              setState(() => _statusFilters.remove(status));
              _loadIdeas();
            },
          ),
        ),
        ..._problemFilters.map(
          (problemId) => InputChip(
            avatar: const Icon(AppIcons.problems, size: 16),
            label: Text(problems[problemId] ?? problemId),
            onDeleted: () {
              setState(() => _problemFilters.remove(problemId));
              _loadIdeas();
            },
          ),
        ),
        ..._departmentFilters.map(
          (dep) => InputChip(
            label: Text(dep),
            onDeleted: () {
              setState(() => _departmentFilters.remove(dep));
              _loadIdeas();
            },
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(IdeaStatus status) => IdeaStatusHelpers.icon(status);

  String _statusLabel(IdeaStatus status) => IdeaStatusHelpers.label(status);

  bool get _hasAnyActiveFilter =>
      _statusFilters.isNotEmpty || _problemFilters.isNotEmpty || _departmentFilters.isNotEmpty;
}

