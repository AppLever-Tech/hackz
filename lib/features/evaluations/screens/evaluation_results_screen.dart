import 'dart:async';

import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../workspace/evaluation_details_workspace.dart';
import '../../user/models/user_model.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../widgets/data_view/data_table_view.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../services/evaluation_ranking_service.dart';
import '../services/evaluation_results_query_service.dart';
import '../services/idea_shortlisting_service.dart';
import '../widgets/evaluation_results_table_columns.dart';
import '../../ideathons/screens/create_ideathon_workspace.dart';
import '../../ideathons/services/ideathon_readiness_service.dart';
import '../../ideathons/widgets/ideathon_readiness_banner.dart';

/// Department-admin workspace for reviewing evaluation outcomes and shortlisting.
class EvaluationResultsScreen extends StatefulWidget {
  const EvaluationResultsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EvaluationResultsScreen> createState() => _EvaluationResultsScreenState();
}

class _EvaluationResultsScreenState extends State<EvaluationResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  Future<EvaluationResultsQueryResult>? _future;
  Future<IdeathonReadiness>? _readinessFuture;
  EvaluationResultsMetrics _metrics = EvaluationResultsMetrics.empty;
  List<String> _categories = <String>[];
  List<String> _departments = <String>[];

  bool _showFilters = false;
  bool _saving = false;
  Set<IdeaStatus> _statusFilters = <IdeaStatus>{};
  Set<String> _departmentFilters = <String>{};
  Set<String> _categoryFilters = <String>{};
  String? _activeSortKey;
  bool _sortDescending = true;
  @override
  void initState() {
    super.initState();
    _load();
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _load() {
    setState(() {
      _readinessFuture = IdeathonReadinessService.compute(
        orgId: widget.user.orgId,
        departmentCode: widget.user.departmentCode,
      );
      _future = EvaluationResultsQueryService.fetch(
        EvaluationResultsQueryParams(
          viewer: widget.user,
          search: _searchController.text,
          statusFilters: _statusFilters,
          departmentFilters: _departmentFilters,
          categoryFilters: _categoryFilters,        ),
      ).then((EvaluationResultsQueryResult result) {
        unawaited(EvaluationRankingService.persistRanks(result.rows));
        return result;
      });
    });
  }

  Future<void> _shortlist(EvaluationResultsRow row) async {
    if (_saving) return;
    setState(() => _saving = true);
    await IdeaShortlistingService.shortlistIdea(row.idea.ideaId);
    if (!mounted) return;
    setState(() => _saving = false);
    _load();
    FeedbackService.showSuccess(context, title: 'Shortlisted', message: 'Idea moved to shortlisted.');
  }

  Future<void> _openCreateIdeathon(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: const Text('Create Ideathon')),
          body: CreateIdeathonWorkspace(
            user: widget.user,
            onCreated: (_) => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
    _load();
  }

  Future<void> _reject(EvaluationResultsRow row) async {
    if (_saving) return;
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Reject idea?',
      message: 'This idea will be marked as rejected.',
      confirmLabel: 'Reject',
      dangerConfirm: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    await IdeaShortlistingService.rejectIdea(row.idea.ideaId);
    if (!mounted) return;
    setState(() => _saving = false);
    _load();
    FeedbackService.showSuccess(context, title: 'Rejected', message: 'Idea marked as rejected.');
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
    if (idx >= 0) return idx;
    if (status == IdeaStatus.rejected) {
      return IdeaStatus.lifecycleOrder.indexOf(IdeaStatus.evaluated) + 1;
    }
    return 999;
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
      onOpenIdea: (EvaluationResultsRow row) => showEvaluationDetailsPane(
        context,
        ideaId: row.idea.ideaId,
        viewer: widget.user,
      ),
      onShortlist: _shortlist,
      onReject: _reject,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FutureBuilder<EvaluationResultsQueryResult>(
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
            }

            final bool mobile = ResponsiveHelper.isMobile(context);

            final Widget content = rows.isEmpty
                ? _EmptyState(onClear: () {
                    _searchController.clear();
                    _clearFilters();
                  })
                : mobile
                    ? ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int index) {
                          return EvaluationResultsRowCard(
                            row: rows[index],
                            actions: actions,
                          );
                        },
                      )
                    : DataTableView<EvaluationResultsRow>(
                        items: rows,
                        columns: EvaluationResultsTableColumns.build(actions: actions),
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

                if (mobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Flexible(flex: 2, child: SingleChildScrollView(child: header)),
                      Expanded(flex: 5, child: content),
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
            );          },
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required EvaluationResultsMetrics metrics,
    required List<String> categories,
    required List<String> departments,
  }) {
    final bool compact = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ResponsiveMetricGrid(
          spacing: compact ? 8 : null,
          runSpacing: compact ? 8 : null,
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Total Evaluated',
              value: '${metrics.totalEvaluated}',
              color: const Color(0xFF6A38FF),
              icon: AppIcons.statusEvaluated,
            ),
            DashboardMetricChipData.single(
              label: 'Shortlisted',
              value: '${metrics.shortlisted}',
              color: const Color(0xFF059669),
              icon: AppIcons.statusShortlisted,
            ),
            DashboardMetricChipData.single(
              label: 'Rejected',
              value: '${metrics.rejected}',
              color: const Color(0xFFDC2626),
              icon: AppIcons.statusRejected,
            ),
            DashboardMetricChipData.single(
              label: 'Pending Review',
              value: '${metrics.pendingReview}',
              color: const Color(0xFFEA580C),
              icon: AppIcons.statusUnderEvaluation,
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        FutureBuilder<IdeathonReadiness>(
          future: _readinessFuture,
          builder: (BuildContext context, AsyncSnapshot<IdeathonReadiness> readinessSnap) {
            if (!readinessSnap.hasData) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: compact ? 8 : 12),
              child: IdeathonReadinessBanner(
                readiness: readinessSnap.data!,
                onCreateIdeathon: () => _openCreateIdeathon(context),
              ),
            );
          },
        ),
        ResponsiveSearchFilterBar(
          searchController: _searchController,
          searchHint: 'Search idea or problem title',
          filtersExpanded: _showFilters,
          onToggleFilters: () => setState(() => _showFilters = !_showFilters),
          onSearchSubmitted: _load,
          iconOnlyFilterOnMobile: true,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(top: compact ? 6 : 12),
            child: _buildFiltersPanel(
              context: context,
              categories: categories,
              departments: departments,
            ),
          ),
          crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
        if (_hasActiveFilters) ...<Widget>[
          SizedBox(height: compact ? 6 : 10),
          _buildActiveFilters(),
        ],
      ],
    );
  }

  Widget _buildFiltersPanel({
    required BuildContext context,
    required List<String> categories,
    required List<String> departments,
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
          Text('Status', style: sectionLabel),
          SizedBox(height: chipGap),
          Wrap(
            spacing: chipGap,
            runSpacing: chipGap,
            children: <Widget>[
              for (final IdeaStatus status in <IdeaStatus>[
                IdeaStatus.evaluated,
                IdeaStatus.shortlisted,
                IdeaStatus.rejected,
              ])
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
          if (departments.isNotEmpty) ...<Widget>[
            SizedBox(height: sectionGap),
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
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

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
            const Text(
              'No evaluation results',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}
