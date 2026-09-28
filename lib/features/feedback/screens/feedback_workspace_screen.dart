import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/ui/inputs/filter_pill.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../utils/common_helpers.dart';
import '../../user/models/user_model.dart';
import '../dialogs/feedback_submit_dialog.dart';
import '../models/feedback_model.dart';
import '../models/feedback_status.dart';
import '../models/feedback_type.dart';
import '../services/hackz_feedback_service.dart';
import '../widgets/feedback_status_pill.dart';
import '../widgets/feedback_type_pill.dart';

enum FeedbackWorkspaceMode { mine, all }

/// Feedback list workspace — My Feedback or All Feedback (SysAdmin).
///
/// When [embedded] is true, renders body only for the dashboard chrome overlay.
/// Prefer [onOpenDetails] so the parent overlay can nest the detail pane.
class FeedbackWorkspaceScreen extends StatefulWidget {
  const FeedbackWorkspaceScreen({
    super.key,
    required this.user,
    required this.mode,
    this.embedded = false,
    this.onOpenDetails,
  });

  final UserModel user;
  final FeedbackWorkspaceMode mode;
  final bool embedded;
  final ValueChanged<FeedbackModel>? onOpenDetails;

  @override
  State<FeedbackWorkspaceScreen> createState() => _FeedbackWorkspaceScreenState();
}

class _FeedbackWorkspaceScreenState extends State<FeedbackWorkspaceScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  Future<List<FeedbackModel>>? _future;
  bool _showFilters = false;
  FeedbackType? _typeFilter;
  FeedbackStatus? _statusFilter;
  DateTimeRange? _dateRange;

  bool get _isAll => widget.mode == FeedbackWorkspaceMode.all;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () => setState(() {}));
  }

  void _load() {
    setState(() {
      _future = _isAll
          ? HackzFeedbackService.fetchAll()
          : HackzFeedbackService.fetchMine(widget.user.userId);
    });
  }

  List<FeedbackModel> _applyFilters(List<FeedbackModel> source) {
    final String q = _search.text.trim().toLowerCase();
    return source.where((FeedbackModel f) {
      if (q.isNotEmpty && !f.title.toLowerCase().contains(q)) return false;
      if (_typeFilter != null && f.type != _typeFilter) return false;
      if (_statusFilter != null && f.status != _statusFilter) return false;
      if (_dateRange != null) {
        final DateTime d = DateTime(f.createdAt.year, f.createdAt.month, f.createdAt.day);
        final DateTime start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final DateTime end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
        );
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  ({int open, int inReview, int completed, int closed}) _metrics(List<FeedbackModel> rows) {
    int open = 0, inReview = 0, completed = 0, closed = 0;
    for (final FeedbackModel f in rows) {
      switch (f.status) {
        case FeedbackStatus.open:
          open++;
        case FeedbackStatus.inReview:
          inReview++;
        case FeedbackStatus.completed:
          completed++;
        case FeedbackStatus.closed:
          closed++;
      }
    }
    return (open: open, inReview: inReview, completed: completed, closed: closed);
  }

  void _openDetails(FeedbackModel item) {
    widget.onOpenDetails?.call(item);
  }

  Future<void> _submit() async {
    final bool? ok = await showFeedbackSubmitDialog(
      context: context,
      user: widget.user,
      screenName: _isAll ? 'Feedback Workspace' : 'My Feedback',
    );
    if (ok == true) _load();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (picked == null) return;
    setState(() => _dateRange = picked);
  }

  Widget _submitButton({required bool compact}) {
    return FilledButton.icon(
      onPressed: _submit,
      icon: const Icon(AppIcons.add, size: 16),
      label: const Text('Submit'),
      style: MobileToolbarButtonStyles.filled(compact: compact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);

    return FutureBuilder<List<FeedbackModel>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<FeedbackModel>> snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: HkzProgressIndicator(size: 36));
        }
        if (snap.hasError) {
          return Center(child: Text('Unable to load feedback: ${snap.error}'));
        }
        final List<FeedbackModel> all = snap.data ?? const <FeedbackModel>[];
        final List<FeedbackModel> rows = _applyFilters(all);
        final metrics = _metrics(all);

        return Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 12 : 20, 12, mobile ? 12 : 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ResponsiveListMetrics(
                chips: <DashboardMetricChipData>[
                  DashboardMetricChipData.single(
                    label: 'Open',
                    value: '${metrics.open}',
                    color: const Color(0xFF2563EB),
                    icon: Icons.fiber_new_rounded,
                  ),
                  DashboardMetricChipData.single(
                    label: 'In Review',
                    value: '${metrics.inReview}',
                    color: const Color(0xFFD97706),
                    icon: Icons.hourglass_top_rounded,
                  ),
                  DashboardMetricChipData.single(
                    label: 'Completed',
                    value: '${metrics.completed}',
                    color: const Color(0xFF059669),
                    icon: Icons.check_circle_outline,
                  ),
                  DashboardMetricChipData.single(
                    label: 'Closed',
                    value: '${metrics.closed}',
                    color: const Color(0xFF64748B),
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
                stripSegments: <MetricKpiSegment>[
                  MetricKpiSegment.count(metrics.open, 'Open'),
                  MetricKpiSegment.count(metrics.inReview, 'In Review'),
                  MetricKpiSegment.count(metrics.completed, 'Completed'),
                  MetricKpiSegment.count(metrics.closed, 'Closed'),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveSearchFilterBar(
                searchController: _search,
                searchHint: 'Search by title',
                filtersExpanded: _showFilters,
                onToggleFilters: () => setState(() => _showFilters = !_showFilters),
                iconOnlyFilterOnMobile: true,
                leading: <Widget>[_submitButton(compact: mobile)],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      FilterPill(
                        icon: Icons.category_outlined,
                        label: _typeFilter?.label ?? 'Type',
                        count: _typeFilter == null
                            ? all.length
                            : rows.where((FeedbackModel f) => f.type == _typeFilter).length,
                        selected: _typeFilter != null,
                        onTap: () async {
                          final FeedbackType? picked = await showModalBottomSheet<FeedbackType>(
                            context: context,
                            builder: (BuildContext ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    title: const Text('All types'),
                                    onTap: () => Navigator.pop(ctx),
                                  ),
                                  ...FeedbackType.values.map(
                                    (FeedbackType t) => ListTile(
                                      title: Text(t.label),
                                      onTap: () => Navigator.pop(ctx, t),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          setState(() => _typeFilter = picked);
                        },
                      ),
                      FilterPill(
                        icon: Icons.flag_outlined,
                        label: _statusFilter?.label ?? 'Status',
                        count: _statusFilter == null
                            ? all.length
                            : all.where((FeedbackModel f) => f.status == _statusFilter).length,
                        selected: _statusFilter != null,
                        onTap: () async {
                          final FeedbackStatus? picked =
                              await showModalBottomSheet<FeedbackStatus>(
                            context: context,
                            builder: (BuildContext ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    title: const Text('All statuses'),
                                    onTap: () => Navigator.pop(ctx),
                                  ),
                                  ...FeedbackStatus.lifecycle.map(
                                    (FeedbackStatus s) => ListTile(
                                      title: Text(s.label),
                                      onTap: () => Navigator.pop(ctx, s),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          setState(() => _statusFilter = picked);
                        },
                      ),
                      FilterPill(
                        icon: Icons.date_range_outlined,
                        label: _dateRange == null
                            ? 'Date'
                            : '${formatDateTime(_dateRange!.start).split(' ').first} → ${formatDateTime(_dateRange!.end).split(' ').first}',
                        count: _dateRange == null ? 0 : 1,
                        selected: _dateRange != null,
                        onTap: _pickDateRange,
                      ),
                      if (_typeFilter != null || _statusFilter != null || _dateRange != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _typeFilter = null;
                            _statusFilter = null;
                            _dateRange = null;
                          }),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                crossFadeState:
                    _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          all.isEmpty
                              ? 'No feedback yet. Tap Submit to add one.'
                              : 'No feedback matches your filters.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : mobile
                        ? ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int i) {
                              final FeedbackModel f = rows[i];
                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _openDetails(f),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE3E8F4)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            FeedbackTypePill(type: f.type, compact: true),
                                            const Spacer(),
                                            FeedbackStatusPill(status: f.status, compact: true),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          f.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDateTime(f.createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        if (_isAll) ...<Widget>[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${f.submittedByName} · ${f.role}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : DataTableView<FeedbackModel>(
                            items: rows,
                            onRowTap: _openDetails,
                            columns: <DataTableColumn<FeedbackModel>>[
                              DataTableColumn<FeedbackModel>(
                                label: 'Type',
                                minWidth: 110,
                                cell: (BuildContext _, FeedbackModel f) =>
                                    FeedbackTypePill(type: f.type, compact: true),
                              ),
                              DataTableColumn<FeedbackModel>(
                                label: 'Title',
                                minWidth: 220,
                                flex: 2,
                                cell: (BuildContext _, FeedbackModel f) => Text(
                                  f.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (_isAll)
                                DataTableColumn<FeedbackModel>(
                                  label: 'Reported By',
                                  minWidth: 140,
                                  cell: (BuildContext _, FeedbackModel f) =>
                                      Text(f.submittedByName),
                                ),
                              if (_isAll)
                                DataTableColumn<FeedbackModel>(
                                  label: 'Role',
                                  minWidth: 120,
                                  cell: (BuildContext _, FeedbackModel f) => Text(f.role),
                                ),
                              if (_isAll)
                                DataTableColumn<FeedbackModel>(
                                  label: 'Organization',
                                  minWidth: 140,
                                  cell: (BuildContext _, FeedbackModel f) =>
                                      Text(f.organizationDisplayName),
                                ),
                              DataTableColumn<FeedbackModel>(
                                label: _isAll ? 'Created Date' : 'Created On',
                                minWidth: 140,
                                cell: (BuildContext _, FeedbackModel f) =>
                                    Text(formatDateTime(f.createdAt)),
                              ),
                              DataTableColumn<FeedbackModel>(
                                label: 'Status',
                                minWidth: 110,
                                cell: (BuildContext _, FeedbackModel f) =>
                                    FeedbackStatusPill(status: f.status, compact: true),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
