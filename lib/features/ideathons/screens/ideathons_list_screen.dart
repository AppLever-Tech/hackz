import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/ui/filters/hackz_filter_pane.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/empty_search_state.dart';
import '../widgets/ideathon_metrics_row.dart';
import '../../user/models/user_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../../events/models/event_kind.dart';
import '../../events/widgets/event_kind_pill.dart';
import '../services/ideathon_query_service.dart';
import '../services/ideathon_status_helpers.dart';
import '../widgets/event_commercial_access_pill.dart';
import '../widgets/ideathon_status_pill.dart';
import '../widgets/ideathon_type_pill.dart';
import 'create_ideathon_workspace.dart';
import 'ideathon_details_pane.dart';

class IdeathonsListScreen extends StatefulWidget {
  const IdeathonsListScreen({
    super.key,
    required this.user,
    this.eventKind,
  });

  final UserModel user;
  /// When set, the list is limited to one template. Null shows every event.
  final EventKind? eventKind;

  @override
  State<IdeathonsListScreen> createState() => _IdeathonsListScreenState();
}

class _IdeathonsListScreenState extends State<IdeathonsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showCreate = false;
  Set<IdeathonStatus> _statusFilters = <IdeathonStatus>{};
  Set<EventKind> _templateFilters = <EventKind>{};
  late Future<List<IdeathonListRow>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = IdeathonQueryService.fetch(
        IdeathonQueryParams(
          viewer: widget.user,
          search: _searchController.text,
          statusFilters: _statusFilters,
          eventKind: widget.eventKind,
          templateFilters: _templateFilters,
        ),
      );
    });
  }

  void _openIdeathon(String id) =>
      showIdeathonDetailsPane(
        context,
        ideathonId: id,
        actor: widget.user,
        backTooltip: 'Back to Events',
        onDeleted: _load,
      );

  void _clearAllFilters() {
    setState(() {
      _statusFilters = <IdeathonStatus>{};
      _templateFilters = <EventKind>{};
      _load();
    });
  }

  void _toggleStatusFilter(IdeathonStatus status) {
    setState(() {
      if (_statusFilters.contains(status)) {
        _statusFilters.remove(status);
      } else {
        _statusFilters.add(status);
      }
      _load();
    });
  }

  void _toggleTemplateFilter(EventKind kind) {
    setState(() {
      if (_templateFilters.contains(kind)) {
        _templateFilters.remove(kind);
      } else {
        _templateFilters.add(kind);
      }
      _load();
    });
  }

  bool get _canCreate =>
      RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(widget.user.role));

  IdeathonModel? _inProgressEvent(List<IdeathonListRow> rows) {
    final List<IdeathonModel> inProgress = rows
        .map((IdeathonListRow row) => row.ideathon)
        .where((IdeathonModel event) => event.status == IdeathonStatus.inProgress)
        .toList(growable: false);
    if (inProgress.isEmpty) return null;
    final DateTime now = DateTime.now();
    for (final IdeathonModel event in inProgress) {
      final DateTime start = event.startDateTime.toLocal();
      final DateTime end = event.endDateTime.toLocal();
      if (!now.isBefore(start) && !now.isAfter(end)) return event;
    }
    return inProgress.first;
  }

  InputDecoration _searchDecoration() {
    return HackzInputDecoration.decorate(
      hintText: 'Search events',
      prefixIcon: const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
      compact: true,
    );
  }

  Widget _buildFiltersPanel() {
    return HackzFilterPane(
      onClearAll: _clearAllFilters,
      sections: <Widget>[
        HackzFilterSection.chips(
          icon: AppIcons.filter,
          label: 'Status',
          chips: IdeathonStatus.values
              .map(
                (IdeathonStatus status) => HackzFilterChips.toggle(
                  icon: IdeathonStatusHelpers.icon(status),
                  label: IdeathonStatusHelpers.label(status),
                  selected: _statusFilters.contains(status),
                  onSelected: (_) => _toggleStatusFilter(status),
                ),
              )
              .toList(growable: false),
        ),
        if (widget.eventKind == null)
          HackzFilterSection.chips(
            icon: AppIcons.event,
            label: 'Template',
            chips: EventKind.values
                .map(
                  (EventKind kind) => HackzFilterChips.toggle(
                    icon: kind.icon,
                    label: kind.templateLabel,
                    selected: _templateFilters.contains(kind),
                    onSelected: (_) => _toggleTemplateFilter(kind),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildListHeader({
    required BuildContext context,
    required List<IdeathonListRow> rows,
    required IdeathonModel? inProgress,
  }) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget metrics = IdeathonMetricsRow(
      rows: rows,
      spacing: mobile ? 8 : 10,
      runSpacing: mobile ? 8 : 10,
    );
    final Widget searchBar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search events',
      searchDecoration: _searchDecoration(),
      searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      iconOnlyFilterOnMobile: true,
    );
    final Widget toolbar = !mobile && _canCreate
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MobileToolbarButtonStyles.filledIcon(
                onPressed: () => setState(() => _showCreate = true),
                label: 'Create Event',
              ),
              const SizedBox(width: 8),
              Expanded(child: searchBar),
            ],
          )
        : searchBar;
    final Widget filters = AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: _buildFiltersPanel(),
      crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        metrics,
        if (inProgress != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _InProgressEventPill(
              name: inProgress.name,
              onTap: () => _openIdeathon(inProgress.ideathonId),
            ),
          ),
        ],
        SizedBox(height: mobile ? 8 : 12),
        toolbar,
        SizedBox(height: mobile ? 6 : 12),
        filters,
        SizedBox(height: mobile ? 6 : 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreate && _canCreate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                IconButton(onPressed: () => setState(() => _showCreate = false), icon: const Icon(AppIcons.back)),
                Text('Create Event', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: CreateIdeathonWorkspace(
              user: widget.user,
              eventKind: widget.eventKind ?? EventKind.ideathon,
              onCreated: (String id) {
                setState(() => _showCreate = false);
                _load();
                _openIdeathon(id);
              },
            ),
          ),
        ],
      );
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    return FutureBuilder<List<IdeathonListRow>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<IdeathonListRow>> snapshot) {
        final List<IdeathonListRow> rows = snapshot.data ?? const <IdeathonListRow>[];
        final IdeathonModel? inProgress = _inProgressEvent(rows);

        return Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildListHeader(context: context, rows: rows, inProgress: inProgress),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : rows.isEmpty
                          ? EmptySearchState.events(
                              listLabel: 'Events',
                              icon: AppIcons.event,
                              onClearSearch: () {
                                _searchController.clear();
                                _clearAllFilters();
                              },
                            )
                          : ListView.separated(
                              padding: EdgeInsets.only(
                                bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 0,
                              ),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (BuildContext context, int index) {
                                final row = rows[index].ideathon;
                                return InkWell(
                                  onTap: () => _openIdeathon(row.ideathonId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: kDashboardCardDecoration,
                                    child: Row(
                                      children: <Widget>[
                                        Icon(row.eventKind.icon, color: const Color(0xFF6A38FF)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(row.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                              Text(
                                                '${row.ideaCount} ${row.ideaCount == 1 ? row.eventKind.payableItemLabel.toLowerCase() : row.eventKind.entriesLabel.toLowerCase()} · ${formatDateTime(row.startDateTime.toLocal())}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Flexible(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.end,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: <Widget>[
                                              EventKindPill(kind: row.eventKind),
                                              IdeathonTypePill(type: row.ideathonType),
                                              IdeathonStatusPill(status: row.status),
                                            if (!row.commercialAccess.isEnabled)
                                              EventCommercialAccessPill(access: row.commercialAccess),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
            if (mobile && _canCreate)
              MobileCreateFab(
                onPressed: () => setState(() => _showCreate = true),
                tooltip: 'Create Event',
              ),
          ],
        );
      },
    );
  }
}

class _InProgressEventPill extends StatelessWidget {
  const _InProgressEventPill({
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = IdeathonStatusHelpers.color(IdeathonStatus.inProgress);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: IdeathonStatusHelpers.background(IdeathonStatus.inProgress),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(IdeathonStatusHelpers.icon(IdeathonStatus.inProgress), size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name.trim().isEmpty ? 'In progress' : name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Today',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
