import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../workspace/evaluation_details_workspace.dart';
import '../../user/models/user_model.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../widgets/evaluation_results_metrics_row.dart';
import '../services/evaluation_ranking_service.dart';
import '../services/evaluation_results_query_service.dart';
import '../widgets/evaluation_results_table_columns.dart';

/// Department-admin workspace for reviewing evaluation outcomes and rankings.
///
/// Optional [ideathonId] scopes the same UX to one Ideathon — no second screen.
class EvaluationResultsScreen extends StatefulWidget {
  const EvaluationResultsScreen({
    super.key,
    required this.user,
    this.ideathonId = '',
    this.ideathonName = '',
    this.embedded = false,
  });

  final UserModel user;
  final String ideathonId;
  final String ideathonName;

  /// When true, skip the Ideathon context banner (used inside Event Details).
  final bool embedded;

  @override
  State<EvaluationResultsScreen> createState() => _EvaluationResultsScreenState();
}

class _EvaluationResultsScreenState extends State<EvaluationResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<EvaluationResultsQueryResult>? _future;
  EvaluationResultsMetrics _metrics = EvaluationResultsMetrics.empty;
  List<String> _categories = <String>[];
  List<String> _departments = <String>[];
  String _ideathonName = '';
  String _templateId = '';

  bool _showFilters = false;
  final Set<IdeaStatus> _statusFilters = <IdeaStatus>{};
  final Set<String> _departmentFilters = <String>{};
  final Set<String> _categoryFilters = <String>{};
  String? _activeSortKey;
  bool _sortDescending = true;

  String get _eventId => widget.ideathonId.trim();
  bool get _isIdeathonScoped => _eventId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ideathonName = widget.ideathonName.trim();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant EvaluationResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ideathonId != widget.ideathonId || oldWidget.user.userId != widget.user.userId) {
      _ideathonName = widget.ideathonName.trim();
      _load();
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _load() {
    setState(() {
      _future = EvaluationResultsQueryService.fetch(
        EvaluationResultsQueryParams(
          viewer: widget.user,
          search: _searchController.text,
          statusFilters: _statusFilters,
          departmentFilters: _departmentFilters,
          categoryFilters: _categoryFilters,
          ideathonId: _eventId,
        ),
      ).then((EvaluationResultsQueryResult result) {
        // Never persist Idea ranks from Ideathon-scoped display ordering.
        if (!result.isIdeathonScoped) {
          unawaited(EvaluationRankingService.persistRanks(result.rows));
        }
        return result;
      });
    });
  }

  List<EvaluationResultsRow> _sortedRows(List<EvaluationResultsRow> rows) {
    if (_activeSortKey == null) return rows;
    final List<EvaluationResultsRow> sorted = List<EvaluationResultsRow>.from(rows);
    int compare(EvaluationResultsRow a, EvaluationResultsRow b) {
      switch (_activeSortKey) {
        case 'average':
          return (a.aggregate.averageScore ?? -1).compareTo(b.aggregate.averageScore ?? -1);
        case 'highest':
          return (a.aggregate.highestScore ?? -1).compareTo(b.aggregate.highestScore ?? -1);
        case 'lowest':
          return (a.aggregate.lowestScore ?? -1).compareTo(b.aggregate.lowestScore ?? -1);
        case 'status':
          if (_isIdeathonScoped) {
            return (a.evaluationComplete ? 1 : 0).compareTo(b.evaluationComplete ? 1 : 0);
          }
          return _statusSortIndex(a.idea.status).compareTo(_statusSortIndex(b.idea.status));
        default:
          return 0;
      }
    }

    sorted.sort((EvaluationResultsRow a, EvaluationResultsRow b) {
      final int result = compare(a, b);
      return _sortDescending ? -result : result;
    });
    return sorted;
  }

  static int _statusSortIndex(IdeaStatus status) {
    final int idx = IdeaStatus.lifecycleOrder.indexOf(status);
    return idx >= 0 ? idx : 999;
  }

  void _onSort(String sortKey) {
    setState(() {
      if (_activeSortKey == sortKey) {
        _sortDescending = !_sortDescending;
      } else {
        _activeSortKey = sortKey;
        _sortDescending = sortKey != 'status';
      }
    });
  }

  EvaluationResultsTableActions _tableActions(BuildContext context) {
    return EvaluationResultsTableActions(
      onOpenIdea: (EvaluationResultsRow row) {
        if (widget.embedded) {
          WorkspaceNavigator.openEvaluation(
            context,
            row.idea.ideaId,
            ideathonId: _eventId,
          );
          return;
        }
        showEvaluationDetailsPane(
          context,
          ideaId: row.idea.ideaId,
          ideathonId: _eventId,
          backTooltip: _isIdeathonScoped ? 'Back to Ideathon Results' : 'Back to Evaluation Results',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EvaluationResultsQueryResult>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<EvaluationResultsQueryResult> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load results: ${snapshot.error}'));
        }

        final EvaluationResultsQueryResult? data = snapshot.data;
        final List<EvaluationResultsRow> rows = _sortedRows(data?.rows ?? const <EvaluationResultsRow>[]);
        final EvaluationResultsMetrics metrics = data?.metrics ?? _metrics;
        final List<String> categories = data?.categories ?? _categories;
        final List<String> departments = data?.departments ?? _departments;
        final EvaluationResultsTableActions actions = _tableActions(context);

        if (data != null) {
          _metrics = data.metrics;
          _categories = data.categories;
          _departments = data.departments;
          if (data.ideathonName.trim().isNotEmpty) {
            _ideathonName = data.ideathonName.trim();
          }
          _templateId = data.evaluationTemplateId.trim();
        }

        final bool mobile = ResponsiveHelper.isMobile(context);
        final bool ideathonScoped = data?.isIdeathonScoped ?? _isIdeathonScoped;

        final Widget content = rows.isEmpty
            ? _EmptyState(
                onClear: () {
                  _searchController.clear();
                  _clearFilters();
                },
                ideathonScoped: ideathonScoped,
              )
            : mobile
                ? ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      return EvaluationResultsRowCard(
                        row: rows[index],
                        actions: actions,
                        ideathonScoped: ideathonScoped,
                      );
                    },
                  )
                : DataTableView<EvaluationResultsRow>(
                    items: rows,
                    columns: EvaluationResultsTableColumns.build(
                      actions: actions,
                      ideathonScoped: ideathonScoped,
                    ),
                    onSort: _onSort,
                    activeSortKey: _activeSortKey,
                  );
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final Widget header = _buildHeader(
              context: context,
              metrics: metrics,
              categories: categories,
              departments: departments,
              ideathonScoped: ideathonScoped,
            );

            if (!hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  SizedBox(height: mobile ? 560 : 420, child: content),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required EvaluationResultsMetrics metrics,
    required List<String> categories,
    required List<String> departments,
    required bool ideathonScoped,
  }) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final Widget? contextBanner =
        ideathonScoped && !widget.embedded ? _buildIdeathonBanner(compact: compact) : null;
    final Widget metricsRow = EvaluationResultsMetricsRow(
      metrics: metrics,
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
    );
    final Widget searchBar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search idea or problem title',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      onSearchSubmitted: _load,
      iconOnlyFilterOnMobile: true,
    );
    final Widget filters = AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: EdgeInsets.only(top: compact ? 6 : 12),
        child: _buildFiltersPanel(
          context: context,
          categories: categories,
          departments: departments,
          ideathonScoped: ideathonScoped,
        ),
      ),
      crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 180),
    );
    final Widget? activeFilters = _hasActiveFilters ? _buildActiveFilters() : null;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (contextBanner != null) ...<Widget>[
            contextBanner,
            const SizedBox(height: 8),
          ],
          metricsRow,
          const SizedBox(height: 8),
          searchBar,
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
      children: <Widget>[
        if (contextBanner != null) ...<Widget>[
          contextBanner,
          const SizedBox(height: 12),
        ],
        metricsRow,
        const SizedBox(height: 12),
        searchBar,
        filters,
        if (activeFilters != null) ...<Widget>[
          const SizedBox(height: 10),
          activeFilters,
        ],
      ],
    );
  }

  Widget _buildIdeathonBanner({required bool compact}) {
    final String name = _ideathonName.isEmpty ? 'this Ideathon' : _ideathonName;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(AppIcons.results, size: 18, color: Color(0xFF4A67FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ideathon Evaluation Results · $name',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scores and completion are scoped to this event only. Incomplete evaluations are not treated as final.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.35),
                ),
                if (_templateId.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => WorkspaceNavigator.openEvaluationTemplate(context, _templateId),
                    borderRadius: BorderRadius.circular(4),
                    child: const Text(
                      'View evaluation template',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel({
    required BuildContext context,
    required List<String> categories,
    required List<String> departments,
    required bool ideathonScoped,
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
          if (!ideathonScoped) ...<Widget>[
            Text('Status', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: <Widget>[
                for (final IdeaStatus status in IdeaStatus.lifecycleOrder)
                  MobileFilterPaneStyles.filterChip(
                    compact: compact,
                    label: IdeaStatusHelpers.label(status),
                    selected: _statusFilters.contains(status),
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          _statusFilters.add(status);
                        } else {
                          _statusFilters.remove(status);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
          if (departments.isNotEmpty) ...<Widget>[
            if (!ideathonScoped) SizedBox(height: sectionGap),
            Text('Department', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: departments
                  .map(
                    (String dep) => MobileFilterPaneStyles.filterChip(
                      compact: compact,
                      label: dep,
                      selected: _departmentFilters.contains(dep),
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _departmentFilters.add(dep);
                          } else {
                            _departmentFilters.remove(dep);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          if (categories.isNotEmpty) ...<Widget>[
            SizedBox(height: sectionGap),
            Text('Category', style: sectionLabel),
            SizedBox(height: chipGap),
            Wrap(
              spacing: chipGap,
              runSpacing: chipGap,
              children: categories
                  .map(
                    (String cat) => MobileFilterPaneStyles.filterChip(
                      compact: compact,
                      label: cat,
                      selected: _categoryFilters.contains(cat),
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            _categoryFilters.add(cat);
                          } else {
                            _categoryFilters.remove(cat);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: sectionGap),
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: _clearFilters,
            onApply: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ..._statusFilters.map(
          (IdeaStatus status) => InputChip(
            label: Text(IdeaStatusHelpers.label(status)),
            onDeleted: () {
              setState(() => _statusFilters.remove(status));
              _load();
            },
          ),
        ),
        ..._departmentFilters.map(
          (String dep) => InputChip(
            label: Text(dep),
            onDeleted: () {
              setState(() => _departmentFilters.remove(dep));
              _load();
            },
          ),
        ),
        ..._categoryFilters.map(
          (String cat) => InputChip(
            label: Text(cat),
            onDeleted: () {
              setState(() => _categoryFilters.remove(cat));
              _load();
            },
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilters.clear();
      _departmentFilters.clear();
      _categoryFilters.clear();
    });
    _load();
  }

  bool get _hasActiveFilters =>
      _statusFilters.isNotEmpty || _departmentFilters.isNotEmpty || _categoryFilters.isNotEmpty;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear, this.ideathonScoped = false});

  final VoidCallback onClear;
  final bool ideathonScoped;

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
            const Icon(AppIcons.results, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              ideathonScoped ? 'No Ideathon evaluation results' : 'No evaluation results',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}
