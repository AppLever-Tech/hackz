import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/ui/common/mobile_compact_pill.dart';
import '../widgets/ideathon_metrics_row.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../services/ideathon_query_service.dart';
import '../services/ideathon_status_helpers.dart';
import '../widgets/ideathon_status_pill.dart';
import '../widgets/ideathon_type_pill.dart';
import 'create_ideathon_workspace.dart';
import '../workspace/ideathon_workspace.dart';

class IdeathonsListScreen extends StatefulWidget {
  const IdeathonsListScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<IdeathonsListScreen> createState() => _IdeathonsListScreenState();
}

class _IdeathonsListScreenState extends State<IdeathonsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showCreate = false;
  Set<IdeathonStatus> _statusFilters = <IdeathonStatus>{};
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
        ),
      );
    });
  }

  void _openIdeathon(String id) => IdeathonWorkspace.open(context, id, actor: widget.user);

  void _clearAllFilters() {
    setState(() {
      _statusFilters = <IdeathonStatus>{};
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

  InputDecoration _searchDecoration(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return InputDecoration(
      hintText: 'Search ideathon events',
      prefixIcon: const Icon(AppIcons.search),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFCFDFF),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: mobile ? 10 : 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.3),
      ),
    );
  }

  Widget _buildCreateButton({required bool mobile}) {
    return FilledButton.icon(
      onPressed: () => setState(() => _showCreate = true),
      icon: const Icon(AppIcons.add, size: 16),
      label: Text(mobile ? 'Create' : 'Create'),
      style: MobileToolbarButtonStyles.filled(compact: mobile),
    );
  }

  Widget _buildStatusFilterChip(IdeathonStatus status, {required bool compact}) {
    final bool selected = _statusFilters.contains(status);
    final String label = IdeathonStatusHelpers.label(status);
    final IconData icon = IdeathonStatusHelpers.icon(status);

    if (!compact) {
      return FilterChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => _toggleStatusFilter(status),
      );
    }

    return MobileCompactPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: () => _toggleStatusFilter(status),
    );
  }

  Widget _buildFiltersPanel(BuildContext context) {
    final bool compact = MobileFilterPaneStyles.useCompact(context);
    final double chipGap = MobileFilterPaneStyles.chipGap(compact: compact);

    return MobileFilterPaneStyles.panelShell(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveFilterChipRow(
            spacing: chipGap,
            runSpacing: chipGap,
            children: IdeathonStatus.values
                .map((IdeathonStatus status) => _buildStatusFilterChip(status, compact: compact))
                .toList(growable: false),
          ),
          SizedBox(height: MobileFilterPaneStyles.sectionGap(compact: compact)),
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: _clearAllFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context, {
    required List<IdeathonListRow> rows,
    required IdeathonModel? latest,
  }) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget createButton = _buildCreateButton(mobile: mobile);
    final Widget metrics = IdeathonMetricsRow(
      rows: rows,
      spacing: mobile ? 8 : 10,
      runSpacing: mobile ? 8 : 10,
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          metrics,
          const SizedBox(height: 8),
          ResponsiveSearchFilterBar(
            searchController: _searchController,
            searchHint: 'Search ideathon events',
            searchDecoration: _searchDecoration(context),
            filtersExpanded: _showFilters,
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            iconOnlyFilterOnMobile: true,
          ),
          const SizedBox(height: 6),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFiltersPanel(context),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          if (latest != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _LatestEventPill(
                name: latest.name,
                dateLabel: formatDateTime(latest.startDateTime.toLocal()),
                onTap: () => _openIdeathon(latest.ideathonId),
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: _searchDecoration(context),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: const Icon(AppIcons.filter),
              label: Text(_showFilters ? 'Hide Filters' : 'Filters'),
            ),
            const SizedBox(width: 8),
            createButton,
          ],
        ),
        if (_showFilters) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IdeathonStatus.values
                .map((IdeathonStatus status) => _buildStatusFilterChip(status, compact: false))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: <Widget>[
                IconButton(onPressed: () => setState(() => _showCreate = false), icon: const Icon(AppIcons.back)),
                const Text('Create Ideathon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: CreateIdeathonWorkspace(
              user: widget.user,
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
        final IdeathonModel? latest = rows.isEmpty ? null : rows.first.ideathon;

        return Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!mobile) ...<Widget>[
                    _buildTopPills(rows: rows, latest: latest),
                    const SizedBox(height: 12),
                  ],
                  _buildToolbar(context, rows: rows, latest: latest),
                  const SizedBox(height: 12),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : rows.isEmpty
                            ? const Center(child: Text('No ideathon events yet.'))
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
                                          const Icon(AppIcons.ideathons, color: Color(0xFF6A38FF)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(row.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                Text(
                                                  '${row.ideaCount} ideas · ${formatDateTime(row.startDateTime.toLocal())}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IdeathonTypePill(type: row.ideathonType),
                                          const SizedBox(width: 6),
                                          IdeathonStatusPill(status: row.status),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            if (mobile)
              MobileCreateFab(
                onPressed: () => setState(() => _showCreate = true),
                tooltip: 'Create Ideathon',
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopPills({required List<IdeathonListRow> rows, required IdeathonModel? latest}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IdeathonMetricsRow(rows: rows),
        if (latest != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _LatestEventPill(
              name: latest.name,
              dateLabel: formatDateTime(latest.startDateTime.toLocal()),
              onTap: () => _openIdeathon(latest.ideathonId),
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestEventPill extends StatelessWidget {
  const _LatestEventPill({
    required this.name,
    required this.dateLabel,
    required this.onTap,
  });

  final String name;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.clock, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name.trim().isEmpty ? 'Latest event' : name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            Text(dateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
