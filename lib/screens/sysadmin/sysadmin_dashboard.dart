import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/organization_type.dart';
import '../../models/enums/user_role.dart';
import '../../models/organization_model.dart';
import '../../models/user_model.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/dashboard_components.dart';
import 'organization_dialog.dart';
import 'edit_org_screen.dart';
import 'platform_settings_dashboard.dart';
import '../../utils/firestore_utils.dart';
import '../../widgets/filter_pill.dart';

class SysAdminDashboard extends StatelessWidget {
  const SysAdminDashboard({super.key, required this.user});

  final UserModel user;

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.getTotalOrganizations(),
      FirestoreUtils.getTotalUsers(),
      FirestoreUtils.getActiveUsers(),
      FirestoreUtils.getProblemsCount(),
      FirestoreUtils.getIdeasCount(),
      FirestoreUtils.getOrgStats(),
    ]);

    return <String, dynamic>{
      'totalOrganizations': results[0] as int,
      'totalUsers': results[1] as int,
      'activeUsers': results[2] as int,
      'totalProblems': results[3] as int,
      'totalIdeas': results[4] as int,
      'orgStats': results[5] as List<Map<String, dynamic>>,
    };
  }

  Future<List<OrganizationModel>> _loadOrganizations() {
    return FirestoreUtils.getOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.sysAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: SysAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (BuildContext context, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 3) {
          return PlatformSettingsDashboard(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 1) {
          return _OrganizationDetailsView(
            refreshToken: refreshToken,
            loadOrganizations: _loadOrganizations,
          );
        }
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadDashboardData(),
          builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Unable to load dashboard data: ${snapshot.error}');
            }

            final data = snapshot.data ?? <String, dynamic>{};
            final int totalOrganizations = data['totalOrganizations'] as int? ?? 0;
            final int totalUsers = data['totalUsers'] as int? ?? 0;
            final int activeUsers = data['activeUsers'] as int? ?? 0;
            final int totalProblems = data['totalProblems'] as int? ?? 0;
            final int totalIdeas = data['totalIdeas'] as int? ?? 0;
            final List<Map<String, dynamic>> orgStats =
                data['orgStats'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];

            final int inactiveUsers = (totalUsers - activeUsers).clamp(0, totalUsers);
            final double activePct = totalUsers == 0 ? 0 : (activeUsers / totalUsers);
            final int activationPercent = (activePct * 100).round();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalOrganizations',
                        label: 'Total Organizations',
                        icon: Icons.apartment_outlined,
                        iconBgColor: const Color(0xFFEAF2FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalUsers',
                        label: 'Total Users',
                        icon: Icons.groups_outlined,
                        iconBgColor: const Color(0xFFFFF4E8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalProblems',
                        label: 'Total Problems',
                        icon: Icons.warning_amber_rounded,
                        iconBgColor: const Color(0xFFFFF2E8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCountCard(
                        value: '$totalIdeas',
                        label: 'Total Ideas',
                        icon: Icons.lightbulb_outline,
                        iconBgColor: const Color(0xFFF2EDFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: ChartCard(
                        title: 'Platform Activity',
                        child: const SizedBox(
                          height: 220,
                          child: _LineChartPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChartCard(
                        title: 'Activation Rate',
                        child: SizedBox(
                          height: 220,
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: CircularProgressIndicator(
                                    value: activePct,
                                    strokeWidth: 14,
                                    color: const Color(0xFF6A38FF),
                                    backgroundColor: const Color(0xFFE8ECF8),
                                  ),
                                ),
                                Text(
                                  '$activationPercent% Active\n$inactiveUsers Inactive',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ChartCard(
                  title: 'Organization Snapshot',
                  child: Column(
                    children: orgStats.isEmpty
                        ? const <Widget>[Text('No organizations found')]
                        : orgStats
                            .map(
                              (org) => OrganizationRow(
                                name: (org['name'] as String?) ?? '-',
                                type: (org['type'] as String?) ?? '-',
                                totalUsers: (org['totalUsers'] as int?) ?? 0,
                                activeUsers: (org['activeUsers'] as int?) ?? 0,
                                pendingUsers: (org['pendingUsers'] as int?) ?? 0,
                                totalIdeas: (org['totalIdeas'] as int?) ?? 0,
                              ),
                            )
                            .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'System Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const InsightCard(text: '3 organizations have high pending users'),
                const SizedBox(height: 10),
                const InsightCard(text: '2 organizations inactive for 7 days'),
                const SizedBox(height: 10),
                const InsightCard(text: 'Low engagement in 1 organization'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OrganizationDetailsView extends StatefulWidget {
  const _OrganizationDetailsView({
    required this.refreshToken,
    required this.loadOrganizations,
  });

  final int refreshToken;
  final Future<List<OrganizationModel>> Function() loadOrganizations;

  @override
  State<_OrganizationDetailsView> createState() => _OrganizationDetailsViewState();
}

class _OrganizationDetailsViewState extends State<_OrganizationDetailsView> {
  /// `null` = show all organizations (client-side filter on [_allOrgs]).
  OrganizationType? _typeFilter;

  List<OrganizationModel> _allOrgs = <OrganizationModel>[];
  OrganizationModel? _editingOrg;
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  @override
  void didUpdateWidget(covariant _OrganizationDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _fetchOrganizations();
    }
  }

  Future<void> _fetchOrganizations() async {
    setState(() {
      _loading = true;
      _fetchError = null;
    });
    try {
      final list = await widget.loadOrganizations();
      if (!mounted) return;
      setState(() {
        _allOrgs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = e.toString();
        _loading = false;
      });
    }
  }

  void _refreshList() {
    _fetchOrganizations();
  }

  Map<OrganizationType, int> _countByType(List<OrganizationModel> orgs) {
    final map = <OrganizationType, int>{
      for (final OrganizationType t in OrganizationType.values) t: 0,
    };
    for (final OrganizationModel o in orgs) {
      map[o.type] = (map[o.type] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fetchError != null) {
      return Text('Unable to load organizations: $_fetchError');
    }

    if (_editingOrg != null) {
      return EditOrgScreen(
        key: ValueKey<String>(_editingOrg!.id),
        organization: _editingOrg!,
        embedded: true,
        onBack: () => setState(() => _editingOrg = null),
        onOrganizationsChanged: _refreshList,
      );
    }

    final organizations = _allOrgs;
    final counts = _countByType(organizations);
    final typesPresent =
        OrganizationType.values.where((OrganizationType t) => (counts[t] ?? 0) > 0).toList(growable: false);

    final filtered = _typeFilter == null
        ? organizations
        : organizations.where((OrganizationModel o) => o.type == _typeFilter).toList(growable: false);

    return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          FilterPill(
                            selected: _typeFilter == null,
                            icon: AppIcons.organizations,
                            label: 'All',
                            count: organizations.length,
                            onTap: () => setState(() => _typeFilter = null),
                          ),
                          if (typesPresent.isNotEmpty) ...<Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                height: 28,
                                child: VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            ...typesPresent.map(
                              (OrganizationType t) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterPill(
                                  selected: _typeFilter == t,
                                  icon: AppIcons.forOrganizationType(t),
                                  label: t.displayName,
                                  count: counts[t] ?? 0,
                                  onTap: () => setState(() => _typeFilter = t),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final created = await showOrganizationDialog(context: context);
                      if (created && mounted) {
                        _refreshList();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6A38FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Create Organization'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: filtered.isEmpty
                      ? const <Widget>[Text('No organizations available')]
                      : filtered
                          .map(
                            (OrganizationModel org) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8ECFF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      AppIcons.forOrganizationType(org.type),
                                      size: 22,
                                      color: const Color(0xFF2E43C6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${org.name}\n${org.address}\n${org.website}\n${org.contact}',
                                      style: const TextStyle(height: 1.35),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      org.type.displayName,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => setState(() => _editingOrg = org),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                ),
              ),
            ],
          ),
        );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  const _LineChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(),
      child: Container(),
    );
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ideas = Paint()
      ..color = const Color(0xFF6A38FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final users = Paint()
      ..color = const Color(0xFFFF8C2B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final ideasPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.6, size.height * 0.45)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.3);

    final usersPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.4, size.height * 0.55)
      ..lineTo(size.width * 0.6, size.height * 0.65)
      ..lineTo(size.width * 0.8, size.height * 0.42)
      ..lineTo(size.width, size.height * 0.38);

    canvas.drawPath(ideasPath, ideas);
    canvas.drawPath(usersPath, users);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
