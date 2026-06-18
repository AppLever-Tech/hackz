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
import 'package:hackz/features/payment/widgets/payment_dialog.dart';
import '../../evaluations/widgets/evaluate_idea_dialog.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../widgets/idea_metrics_row.dart';
import 'idea_details_pane.dart';
import '../../evaluations/workspace/evaluation_assignment_details_pane.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
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
  bool _scoreSortDescending = true;

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

  Future<void> _openEvaluateDialog(IdeaListItem item) async {
    final updated = await EvaluateIdeaDialog.showForIdeaListItem(
      context,
      judge: widget.currentUser,
      item: item,
    );
    if (updated == true && mounted) _loadIdeas();
  }

  Future<void> _openUploadPayment(IdeaListItem item) async {
    final team = item.team;
    if (team == null) return;
    final ok = await showPaymentDialog(
      context: context,
      currentUser: widget.currentUser,
      idea: item.idea,
      team: team,
    );
    if (ok == true && mounted) _loadIdeas();
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
        final List<IdeaListItem> displayItems = _displayItems(ideas);

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
                ? _EmptyIdeasState(
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

  /// Row action callbacks wired into table cells (workspace + dialogs).
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
      onOpenPayment: (IdeaListItem item) {
        final payment = item.payment;
        if (payment == null) return;
        WorkspaceNavigator.openPayment(context, payment.paymentId);
      },
      onOpenEvaluation: (IdeaListItem item) =>
          WorkspaceNavigator.openEvaluation(context, item.idea.ideaId),
      onOpenAttachments: (IdeaListItem item) => _openAttachments(context, item),
      onEvaluate: (IdeaListItem item) => _openEvaluateDialog(item),
      onUploadPayment: (IdeaListItem item) => _openUploadPayment(item),
      onAssignJudge: widget.config.canAssignJudge ? _openAssignJudge : null,
    );
  }

  void _openAssignJudge(IdeaListItem item) {
    showEvaluationAssignmentPane(
      context,
      user: widget.currentUser,
      ideaId: item.idea.ideaId,
      backTooltip: 'Back to Ideas',
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
      case IdeaSortType.score:
        return 'score';
    }
  }

  List<IdeaListItem> _displayItems(List<IdeaListItem> items) {
    if (_sort != IdeaSortType.score) return items;
    final List<IdeaListItem> sorted = List<IdeaListItem>.from(items);
    sorted.sort((IdeaListItem a, IdeaListItem b) {
      final int cmp = (a.score?.score ?? -1).compareTo(b.score?.score ?? -1);
      return _scoreSortDescending ? -cmp : cmp;
    });
    return sorted;
  }

  void _onTableSort(String sortKey) {
    switch (sortKey) {
      case 'newest':
        final IdeaSortType next =
            _sort == IdeaSortType.newest ? IdeaSortType.oldest : IdeaSortType.newest;
        if (!widget.config.enabledSorts.contains(next)) return;
        if (next == _sort) return;
        setState(() => _sort = next);
        _loadIdeas();
      case 'score':
        if (!widget.config.enabledSorts.contains(IdeaSortType.score)) return;
        if (_sort == IdeaSortType.score) {
          setState(() => _scoreSortDescending = !_scoreSortDescending);
        } else {
          setState(() {
            _sort = IdeaSortType.score;
            _scoreSortDescending = true;
          });
          _loadIdeas();
        }
    }
  }

  void _openAttachments(BuildContext context, IdeaListItem item) {
    final String? id = item.firstAttachmentId?.trim();
    if (item.attachmentCount == 1 && id != null && id.isNotEmpty) {
      WorkspaceNavigator.openAttachment(context, id);
      return;
    }
    WorkspaceNavigator.openIdea(context, item.idea.ideaId);
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

class _EmptyIdeasState extends StatelessWidget {
  const _EmptyIdeasState({required this.onClearSearch});

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
            const Icon(AppIcons.ideas, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No ideas found',
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
