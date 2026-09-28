import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../../core/responsive/responsive_filter_bar.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../../core/ui/common/card_overflow_menu.dart';
import '../../../../core/ui/data_view/data_table_column.dart';
import '../../../../core/ui/data_view/data_table_view.dart';
import '../../../../core/ui/filters/hackz_filter_pane.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../organization/models/enums/organization_access_status.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../../organization/services/organisation_access.dart';
import '../../../organization/widgets/organization_thumbnail.dart';
import '../../../user/models/user_model.dart';
import '../../../../utils/common_helpers.dart';
import '../actions/organisation_onboarding_actions.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';
import '../widgets/onboarding_status_pill.dart';
import '../widgets/organisation_detail_widgets.dart';
import 'add_organisation_wizard.dart';
import 'organisation_details_pane.dart';

class OrganisationsOnboardingConsole extends StatefulWidget {
  const OrganisationsOnboardingConsole({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<OrganisationsOnboardingConsole> createState() => _OrganisationsOnboardingConsoleState();
}

enum _OrgAccessFilter { all, active, inactive }

enum _OrgCommercialUsabilityFilter { all, usable, notUsable }

class _OrganisationsOnboardingConsoleState extends State<OrganisationsOnboardingConsole> {
  List<OrganisationOnboardingItem> _items = const <OrganisationOnboardingItem>[];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  _OrgAccessFilter _accessFilter = _OrgAccessFilter.all;
  OrganizationCommercialPlan? _planFilter;
  _OrgCommercialUsabilityFilter _commercialFilter = _OrgCommercialUsabilityFilter.all;
  TenantStatus? _routingFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _reload();
  }

  @override
  void didUpdateWidget(covariant OrganisationsOnboardingConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _reload();
    }
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
      final List<OrganisationOnboardingItem> items = await OrganisationOnboardingService.load();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _add() async {
    final bool changed = await showAddOrganisationWizard(context: context);
    if (changed && mounted) _reload();
  }

  void _openDetails(OrganisationOnboardingItem item) {
    showOrganisationDetailsPane(
      context,
      organisationId: item.organization.id,
      onChanged: _reload,
    );
  }

  List<OrganisationOnboardingItem> get _filtered {
    final String query = _searchController.text.trim().toLowerCase();
    return _items.where((OrganisationOnboardingItem item) {
      if (_accessFilter == _OrgAccessFilter.active &&
          item.organization.status != OrganizationAccessStatus.active) {
        return false;
      }
      if (_accessFilter == _OrgAccessFilter.inactive &&
          item.organization.status == OrganizationAccessStatus.active) {
        return false;
      }
      if (_planFilter != null && item.organization.commercialPlan != _planFilter) {
        return false;
      }
      if (_commercialFilter == _OrgCommercialUsabilityFilter.usable &&
          !OrganisationAccess.isGranted(item.organization)) {
        return false;
      }
      if (_commercialFilter == _OrgCommercialUsabilityFilter.notUsable &&
          OrganisationAccess.isGranted(item.organization)) {
        return false;
      }
      if (_routingFilter != null && item.status != _routingFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final String name = item.name.toLowerCase();
      final String code = item.organisationCode.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList(growable: false);
  }

  int get _activeAccessCount =>
      _items.where((OrganisationOnboardingItem i) => i.organization.status == OrganizationAccessStatus.active).length;

  int get _inactiveAccessCount => _items.length - _activeAccessCount;

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(child: _body(mobile)),
        if (mobile && !_loading)
          MobileCreateFab(onPressed: _add, tooltip: 'Create organisation'),
      ],
    );
  }

  Widget _body(bool mobile) {
    if (_loading) {
      return const Center(child: HkzProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Unable to load organisations: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final List<OrganisationOnboardingItem> visible = _filtered;
    final Widget toolbar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search organisation name or code',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      filterLabel: _showFilters ? 'Hide Filters' : 'Show Filters',
      iconOnlyFilterOnMobile: !mobile,
      trailing: mobile
          ? const <Widget>[]
          : <Widget>[
              MobileToolbarButtonStyles.filledIcon(
                onPressed: _add,
                label: 'Create Organisation',
              ),
            ],
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search organisation name or code',
        compact: true,
        prefixIcon: const Icon(AppIcons.search, size: 18),
      ),
      searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
    );

    final Widget listSection = visible.isEmpty
        ? _empty(hasQuery: _searchController.text.trim().isNotEmpty || _hasActiveFilters)
        : mobile
            ? ListView.separated(
                padding: EdgeInsets.only(bottom: mobile ? MobileCreateFabStyles.listBottomPadding : 12),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) => _mobileCard(visible[index]),
              )
            : DataTableView<OrganisationOnboardingItem>(
                items: visible,
                onRowTap: _openDetails,
                columns: _columns(),
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Organisations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customer organisations on the Control Plane — access, commercial plan, and onboarding.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: 14),
        toolbar,
        if (mobile) ...<Widget>[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: MobileToolbarButtonStyles.filledIcon(
              onPressed: _add,
              label: 'Create Organisation',
            ),
          ),
        ],
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _filtersPane(),
          ),
          crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        const SizedBox(height: 14),
        Expanded(child: listSection),
      ],
    );
  }

  bool get _hasActiveFilters =>
      _accessFilter != _OrgAccessFilter.all ||
      _planFilter != null ||
      _commercialFilter != _OrgCommercialUsabilityFilter.all ||
      _routingFilter != null;

  Widget _filtersPane() {
    return HackzFilterPane(
      onClearAll: () => setState(() {
        _accessFilter = _OrgAccessFilter.all;
        _planFilter = null;
        _commercialFilter = _OrgCommercialUsabilityFilter.all;
        _routingFilter = null;
      }),
      sections: <Widget>[
        HackzFilterSection.chips(
          icon: AppIcons.workflowApproved,
          label: 'Organisation access',
          chips: <Widget>[
            HackzFilterChips.choice(
              icon: AppIcons.organizations,
              label: 'All (${_items.length})',
              selected: _accessFilter == _OrgAccessFilter.all,
              onSelected: () => setState(() => _accessFilter = _OrgAccessFilter.all),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowApproved,
              label: 'Active ($_activeAccessCount)',
              selected: _accessFilter == _OrgAccessFilter.active,
              onSelected: () => setState(() => _accessFilter = _OrgAccessFilter.active),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.lock,
              label: 'Inactive ($_inactiveAccessCount)',
              selected: _accessFilter == _OrgAccessFilter.inactive,
              onSelected: () => setState(() => _accessFilter = _OrgAccessFilter.inactive),
            ),
          ],
        ),
        HackzFilterSection.chips(
          icon: AppIcons.payments,
          label: 'Commercial plan',
          chips: <Widget>[
            HackzFilterChips.choice(
              icon: AppIcons.payments,
              label: 'All plans',
              selected: _planFilter == null,
              onSelected: () => setState(() => _planFilter = null),
            ),
            for (final OrganizationCommercialPlan plan in OrganizationCommercialPlan.values)
              HackzFilterChips.choice(
                icon: AppIcons.payments,
                label: plan.label,
                selected: _planFilter == plan,
                onSelected: () => setState(() => _planFilter = plan),
              ),
          ],
        ),
        HackzFilterSection.chips(
          icon: AppIcons.event,
          label: 'Commercial status',
          chips: <Widget>[
            HackzFilterChips.choice(
              icon: AppIcons.event,
              label: 'All',
              selected: _commercialFilter == _OrgCommercialUsabilityFilter.all,
              onSelected: () => setState(() => _commercialFilter = _OrgCommercialUsabilityFilter.all),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowApproved,
              label: 'Usable',
              selected: _commercialFilter == _OrgCommercialUsabilityFilter.usable,
              onSelected: () => setState(() => _commercialFilter = _OrgCommercialUsabilityFilter.usable),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.lock,
              label: 'Not usable',
              selected: _commercialFilter == _OrgCommercialUsabilityFilter.notUsable,
              onSelected: () => setState(() => _commercialFilter = _OrgCommercialUsabilityFilter.notUsable),
            ),
          ],
        ),
        HackzFilterSection.chips(
          icon: AppIcons.verification,
          label: 'Routing / setup',
          chips: <Widget>[
            HackzFilterChips.choice(
              icon: AppIcons.organizations,
              label: 'Any status',
              selected: _routingFilter == null,
              onSelected: () => setState(() => _routingFilter = null),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.clock,
              label: 'Setup',
              selected: _routingFilter == TenantStatus.setup,
              onSelected: () => setState(() => _routingFilter = TenantStatus.setup),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowApproved,
              label: 'Active routing',
              selected: _routingFilter == TenantStatus.active,
              onSelected: () => setState(() => _routingFilter = TenantStatus.active),
            ),
          ],
        ),
      ],
    );
  }

  List<DataTableColumn<OrganisationOnboardingItem>> _columns() {
    return <DataTableColumn<OrganisationOnboardingItem>>[
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Organisation',
        flex: 3,
        minWidth: 200,
        cell: (BuildContext context, OrganisationOnboardingItem row) {
          return Row(
            children: <Widget>[
              OrganizationThumbnail(organization: row.organization, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Code',
        flex: 2,
        minWidth: 120,
        cell: (_, OrganisationOnboardingItem row) {
          final String code = row.organisationCode;
          return Text(
            code.isEmpty ? '—' : code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: code.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            ),
          );
        },
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Access',
        flex: 2,
        minWidth: 110,
        cell: (_, OrganisationOnboardingItem row) {
          final bool active = row.organization.status == OrganizationAccessStatus.active;
          return OrganisationAccessChip(active: active, label: row.organization.status.label);
        },
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Plan',
        flex: 2,
        minWidth: 100,
        cell: (_, OrganisationOnboardingItem row) =>
            OrganisationMetaChip(icon: AppIcons.payments, label: row.organization.commercialPlan.label),
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Commercial',
        flex: 2,
        minWidth: 130,
        cell: (_, OrganisationOnboardingItem row) {
          final bool usable = OrganisationAccess.isGranted(row.organization);
          return OrganisationAccessChip(
            active: usable,
            label: usable ? 'Usable' : 'Not usable',
          );
        },
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: 'Org admin',
        flex: 2,
        minWidth: 120,
        cell: (_, OrganisationOnboardingItem row) {
          final UserModel? admin = row.collegeAdmin;
          if (admin != null) {
            return Text(
              userDisplayName(admin),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            );
          }
          if (row.hackzOrgAdminConfigured) {
            return const Text(
              'Hackz org admin',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            );
          }
          return const Text('—', style: TextStyle(color: Color(0xFF94A3B8)));
        },
      ),
      DataTableColumn<OrganisationOnboardingItem>(
        label: '',
        fixedWidth: 44,
        gapAfter: 0,
        align: Alignment.center,
        cell: (BuildContext context, OrganisationOnboardingItem row) => _actionsMenu(row),
      ),
    ];
  }

  Widget _actionsMenu(OrganisationOnboardingItem item) {
    return CardOverflowMenuButton(
      tooltip: 'Actions',
      dividersBefore: const <String>{'delete'},
      actions: <CardOverflowMenuAction>[
        const CardOverflowMenuAction(value: 'open', icon: AppIcons.organizations, label: 'View details'),
        const CardOverflowMenuAction(value: 'edit', icon: AppIcons.edit, label: 'Edit organisation'),
        if (!item.isComplete)
          const CardOverflowMenuAction(value: 'continue', icon: AppIcons.onboardingNext, label: 'Continue setup'),
        const CardOverflowMenuAction(value: 'delete', icon: AppIcons.delete, label: 'Delete', danger: true),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'open':
            _openDetails(item);
          case 'edit':
            await OrganisationOnboardingActions.editOrganisation(context, item, onChanged: _reload);
          case 'continue':
            await OrganisationOnboardingActions.continueSetup(context, item, onChanged: _reload);
          case 'delete':
            await OrganisationOnboardingActions.deleteOrganisation(context, item, onChanged: _reload);
        }
      },
    );
  }

  Widget _mobileCard(OrganisationOnboardingItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrganizationThumbnail(organization: item.organization, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: <Widget>[
                            OnboardingStatusPill(status: item.status, compact: true),
                            OrganisationAccessChip(
                              active: item.organization.status == OrganizationAccessStatus.active,
                              label: item.organization.status.label,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _actionsMenu(item),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (item.organisationCode.isNotEmpty)
                    OrganisationMetaChip(icon: AppIcons.key, label: item.organisationCode),
                  OrganisationMetaChip(icon: AppIcons.payments, label: item.organization.commercialPlan.label),
                  OrganisationAccessChip(
                    active: OrganisationAccess.isGranted(item.organization),
                    label: OrganisationAccess.isGranted(item.organization) ? 'Usable' : 'Not usable',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty({required bool hasQuery}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(AppIcons.organizations, size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'No organisations match your search or filters.' : 'No organisations yet',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          if (!hasQuery) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Create an organisation to start onboarding.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(AppIcons.add, size: 18),
              label: const Text('Create Organisation'),
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
}
