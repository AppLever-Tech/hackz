import 'package:flutter/material.dart';
import '../../../constants/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../widgets/deptadmin/department_metric_card.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../services/ideathon_query_service.dart';
import '../widgets/ideathon_status_pill.dart';
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

  void _openIdeathon(String id) => IdeathonWorkspace.open(context, id);

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
                IconButton(onPressed: () => setState(() => _showCreate = false), icon: const Icon(Icons.arrow_back)),
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

        return Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopPills(totalEvents: rows.length, latest: latest),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search ideathon events',
                        prefixIcon: const Icon(AppIcons.search),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (mobile)
                    IconButton(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filters',
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filters'),
                    ),
                  const SizedBox(width: 8),
                  if (mobile)
                    IconButton(
                      onPressed: () => setState(() => _showCreate = true),
                      icon: const Icon(AppIcons.add),
                      tooltip: 'Create ideathon',
                      color: const Color(0xFF6A38FF),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => setState(() => _showCreate = true),
                      icon: const Icon(AppIcons.add),
                      label: const Text('Create'),
                    ),
                ],
              ),
              if (_showFilters) ...<Widget>[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: IdeathonStatus.values
                      .map(
                        (IdeathonStatus status) => FilterChip(
                          label: Text(status.name),
                          selected: _statusFilters.contains(status),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _statusFilters.add(status);
                              } else {
                                _statusFilters.remove(status);
                              }
                              _load();
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : rows.isEmpty
                        ? const Center(child: Text('No ideathon events yet.'))
                        : ListView.separated(
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
                                              '${row.ideaCount} ideas · ${formatShortDate(row.eventDate.toLocal())}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
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
        );
      },
    );
  }

  Widget _buildTopPills({required int totalEvents, required IdeathonModel? latest}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ResponsiveMetricGrid(
          chips: <DashboardMetricChipData>[
            DepartmentMetricCard(
              value: '$totalEvents',
              label: 'Total Events',
              icon: AppIcons.ideathons,
              iconBgColor: const Color(0xFFF2EDFF),
              tooltip: 'Ideathon events in this department.',
            ).toChipData(),
          ],
        ),
        if (latest != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _LatestEventPill(
              name: latest.name,
              dateLabel: formatShortDate(latest.eventDate.toLocal()),
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
