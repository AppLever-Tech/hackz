import 'package:flutter/material.dart';

import '../../../../core/firebase/approved_tenant_project.dart';
import '../../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../../core/responsive/responsive_filter_bar.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/common/card_overflow_menu.dart';
import '../../../../core/ui/common/context_pill_metrics.dart';
import '../../../../core/ui/common/context_pill_theme.dart';
import '../../../../core/ui/common/entity_card_pills.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/filters/hackz_filter_pane.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../../core/workspace/context_launch_surface.dart';
import '../../../../utils/common_helpers.dart';
import '../../onboarding/screens/register_workspace_dialog.dart';
import '../services/tenants_admin_service.dart';

enum _TenantUsageFilter { all, available, inUse }

class TenantsManagementConsole extends StatefulWidget {
  const TenantsManagementConsole({super.key});

  @override
  State<TenantsManagementConsole> createState() => _TenantsManagementConsoleState();
}

class _TenantsManagementConsoleState extends State<TenantsManagementConsole> {
  List<RegisteredTenantRow> _rows = const <RegisteredTenantRow>[];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  _TenantUsageFilter _usageFilter = _TenantUsageFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<RegisteredTenantRow> rows = await TenantsAdminService.loadRegisteredTenants();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<RegisteredTenantRow> get _filteredRows {
    final String query = _searchController.text.trim().toLowerCase();
    return _rows.where((RegisteredTenantRow row) {
      if (_usageFilter == _TenantUsageFilter.available && row.inUse) return false;
      if (_usageFilter == _TenantUsageFilter.inUse && !row.inUse) return false;
      if (query.isEmpty) return true;
      final ApprovedTenantProject p = row.project;
      return p.label.toLowerCase().contains(query) ||
          p.projectId.toLowerCase().contains(query) ||
          row.organisationSummary.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  int get _availableCount => _rows.where((RegisteredTenantRow r) => !r.inUse).length;

  int get _inUseCount => _rows.length - _availableCount;

  Future<void> _register({ApprovedTenantProject? existing}) async {
    final bool saved = await showRegisterTenantDialog(context: context, existing: existing);
    if (saved && mounted) _reload();
  }

  Future<void> _delete(RegisteredTenantRow row) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete tenant registration?',
      message:
          'Remove "${row.project.label.trim().isEmpty ? row.project.projectId : row.project.label}" from the Hackz Control Plane catalog? '
          'This does not delete the Firebase/GCP project or any tenant Firestore, Storage, or Auth data.',
      confirmLabel: 'Delete registration',
      dangerConfirm: true,
    );
    if (!ok) return;
    try {
      await TenantsAdminService.deleteRegistration(row.project.projectId);
      if (mounted) {
        FeedbackService.showSuccess(context, title: 'Tenant removed', message: row.project.projectId);
        _reload();
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Delete blocked', message: '$e');
      }
    }
  }

  void _onAction(RegisteredTenantRow row, String action) {
    switch (action) {
      case 'edit':
        _register(existing: row.project);
      case 'delete':
        _delete(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: HkzProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Unable to load tenants: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<RegisteredTenantRow> visible = _filteredRows;

    final Widget toolbar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search tenant name, project id, or organisation',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      filterLabel: _showFilters ? 'Hide Filters' : 'Show Filters',
      iconOnlyFilterOnMobile: !mobile,
      trailing: <Widget>[
        MobileToolbarButtonStyles.filledIcon(
          onPressed: () => _register(),
          label: mobile ? 'Register' : 'Register Tenant',
        ),
      ],
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search tenant name, project id, or organisation',
        compact: true,
        prefixIcon: const Icon(AppIcons.search, size: 18),
      ),
      searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Tenants',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registered Firebase tenant environments on the Control Plane. '
            'Organisation onboarding connects colleges to these tenants.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 14),
          toolbar,
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: HackzFilterPane(
                onClearAll: () => setState(() => _usageFilter = _TenantUsageFilter.all),
                sections: <Widget>[
                  HackzFilterSection.chips(
                    icon: AppIcons.verification,
                    label: 'Usage',
                    chips: <Widget>[
                      HackzFilterChips.choice(
                        icon: AppIcons.organizations,
                        label: 'All (${_rows.length})',
                        selected: _usageFilter == _TenantUsageFilter.all,
                        onSelected: () => setState(() => _usageFilter = _TenantUsageFilter.all),
                      ),
                      HackzFilterChips.choice(
                        icon: AppIcons.workflowApproved,
                        label: 'Available ($_availableCount)',
                        selected: _usageFilter == _TenantUsageFilter.available,
                        onSelected: () => setState(() => _usageFilter = _TenantUsageFilter.available),
                      ),
                      HackzFilterChips.choice(
                        icon: AppIcons.link,
                        label: 'In use ($_inUseCount)',
                        selected: _usageFilter == _TenantUsageFilter.inUse,
                        onSelected: () => setState(() => _usageFilter = _TenantUsageFilter.inUse),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            _empty(hasQuery: _searchController.text.trim().isNotEmpty || _usageFilter != _TenantUsageFilter.all)
          else if (mobile)
            ...visible.map(
              (RegisteredTenantRow row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _tenantCard(row),
              ),
            )
          else
            _table(visible),
        ],
      ),
    );
  }

  Widget _empty({required bool hasQuery}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(AppIcons.verification, size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'No tenants match your search or filters.' : 'No tenants registered',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
          if (!hasQuery) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Register a Firebase project so organisations can connect to it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _register(),
              icon: const Icon(AppIcons.add, size: 18),
              label: const Text('Register Tenant'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _usageStatusPill(RegisteredTenantRow row) {
    final bool inUse = row.inUse;
    final Color foreground = inUse ? const Color(0xFF1D4ED8) : const Color(0xFF047857);
    final Color surface = inUse ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5);
    final Color border = inUse ? const Color(0xFF93C5FD) : const Color(0xFF6EE7B7);
    final String label = inUse ? 'In use' : 'Available';
    final IconData icon = inUse ? AppIcons.link : AppIcons.workflowApproved;
    final BorderRadius radius = ContextPillMetrics.resolvedBorderRadius(compact: true);

    return ContextLaunchSurface(
      enabled: false,
      onTap: () {},
      semantic: ContextPillSemantic.generic,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        height: ContextPillMetrics.workspaceHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground)),
          ],
        ),
      ),
    );
  }

  Widget _organisationCell(RegisteredTenantRow row) {
    if (!row.inUse) {
      return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: row.linkedOrganisations
          .map(
            (record) => EntityCardPills.workspace(
              record.organisationName.trim().isEmpty ? record.organisationCode : record.organisationName.trim(),
              ContextPillSemantic.generic,
              () {},
              icon: AppIcons.organizations,
              enabled: false,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _actionsMenu(RegisteredTenantRow row) {
    return CardOverflowMenuButton(
      tooltip: 'Actions',
      dividersBefore: const <String>{'delete'},
      actions: <CardOverflowMenuAction>[
        const CardOverflowMenuAction(value: 'edit', icon: AppIcons.edit, label: 'Edit tenant'),
        const CardOverflowMenuAction(value: 'delete', icon: AppIcons.delete, label: 'Delete', danger: true),
      ],
      onSelected: (String value) => _onAction(row, value),
    );
  }

  Widget _tenantCard(RegisteredTenantRow row) {
    final ApprovedTenantProject p = row.project;
    final String title = p.label.trim().isEmpty ? p.projectId : p.label.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(AppIcons.verification, size: 20, color: const Color(0xFF6A38FF)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(p.projectId, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _usageStatusPill(row),
              const SizedBox(width: 8),
              _actionsMenu(row),
            ],
          ),
          const SizedBox(height: 10),
          _organisationCell(row),
          if (p.createdAt != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Registered ${formatDayMonthYear(p.createdAt!.toLocal())}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _table(List<RegisteredTenantRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('Tenant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 2, child: Text('Firebase project', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 3, child: Text('Organisations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                ),
                Expanded(flex: 2, child: Text('Registered', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                SizedBox(
                  width: 72,
                  child: Center(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                ),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            _tableRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _tableRow(RegisteredTenantRow row) {
    final ApprovedTenantProject p = row.project;
    final String title = p.label.trim().isEmpty ? p.projectId : p.label.trim();
    final String registered = p.createdAt == null ? '—' : formatDayMonthYear(p.createdAt!.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.verification, size: 18, color: Color(0xFF6A38FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(p.projectId, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          ),
          Expanded(flex: 3, child: _organisationCell(row)),
          Expanded(flex: 2, child: Center(child: _usageStatusPill(row))),
          Expanded(flex: 2, child: Text(registered, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 72, child: Center(child: _actionsMenu(row))),
        ],
      ),
    );
  }
}
