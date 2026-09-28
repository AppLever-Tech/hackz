import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/common/card_overflow_menu.dart';
import '../../../../core/ui/common/rich_tabs.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../../features/dashboard/chrome/dashboard_chrome_controller.dart';
import '../../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../../features/dashboard/chrome/dashboard_session_scope.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import '../../../../features/organization/models/enums/organization_access_status.dart';
import '../../../../features/organization/models/enums/organization_commercial_plan.dart';
import '../../../../features/organization/services/organisation_access.dart';
import '../../../../features/organization/widgets/organization_thumbnail.dart';
import '../../../organization/models/organization_model.dart' show OrganizationModel;
import '../../org_admin/models/hkz_org_admin.dart';
import '../../org_admin/services/hkz_org_admin_service.dart';
import '../actions/organisation_onboarding_actions.dart';
import '../models/organisation_onboarding_item.dart';
import '../services/organisation_onboarding_service.dart';
import '../widgets/onboarding_readiness_checklist.dart';
import '../widgets/onboarding_status_pill.dart';
import '../widgets/organisation_access_control.dart';
import '../widgets/organisation_detail_widgets.dart';
import '../widgets/organisation_event_commercial_access.dart';
import '../widgets/provisioning_authorization_panel.dart';

void showOrganisationDetailsPane(
  BuildContext context, {
  required String organisationId,
  VoidCallback? onChanged,
}) {
  final DashboardChromeController chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    OrganisationDetailsPane(
      key: ValueKey<String>(organisationId),
      organisationId: organisationId,
      onBack: chrome.clearOverlay,
      onChanged: () {
        onChanged?.call();
      },
    ),
  );
}

class OrganisationDetailsPane extends StatefulWidget {
  const OrganisationDetailsPane({
    super.key,
    required this.organisationId,
    required this.onBack,
    this.onChanged,
  });

  final String organisationId;
  final VoidCallback onBack;
  final VoidCallback? onChanged;

  @override
  State<OrganisationDetailsPane> createState() => _OrganisationDetailsPaneState();
}

class _OrganisationDetailsPaneState extends State<OrganisationDetailsPane> {
  late Future<OrganisationOnboardingItem?> _future;
  HkzOrgAdmin? _hackzOrgAdmin;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = OrganisationOnboardingService.loadByOrganisationId(widget.organisationId);
      _hackzOrgAdmin = null;
    });
    _future.then((OrganisationOnboardingItem? item) {
      if (!mounted || item == null) return;
      final String adminId = (item.tenant?.hackzOrgAdminId ?? '').trim();
      if (adminId.isEmpty) return;
      HkzOrgAdminService.fetchById(adminId).then((HkzOrgAdmin? admin) {
        if (mounted) setState(() => _hackzOrgAdmin = admin);
      });
    });
  }

  void _notifyChanged() {
    _reload();
    widget.onChanged?.call();
  }

  Future<void> _handleDelete(OrganisationOnboardingItem item) async {
    final bool deleted = await OrganisationOnboardingActions.deleteOrganisation(
      context,
      item,
      onChanged: widget.onChanged ?? () {},
    );
    if (deleted && mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);

    return SizedBox.expand(
      child: FutureBuilder<OrganisationOnboardingItem?>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<OrganisationOnboardingItem?> snapshot) {
          final OrganisationOnboardingItem? item = snapshot.data;
          final Widget header = _pageHeader(
            context,
            session: session,
            title: item?.name.trim().isNotEmpty == true ? item!.name.trim() : 'Organisation',
          );

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                const Expanded(child: Center(child: HkzProgressIndicator(size: 36))),
              ],
            );
          }
          if (snapshot.hasError || item == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            snapshot.hasError ? '$snapshot.error' : 'Organisation not found.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: 8),
              _contextBand(context, item),
              Expanded(child: _tabbedBody(item)),
            ],
          );
        },
      ),
    );
  }

  Widget _pageHeader(
    BuildContext context, {
    required DashboardSessionScope session,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: DashboardPageHeader(
        title: title,
        titleIcon: AppIcons.organizations,
        user: session.user,
        onLogout: session.onLogout,
        onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId, actor: session.user),
        onRefresh: _reload,
        helpPageId: 'tenant-onboarding',
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Organisations',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _contextBand(BuildContext context, OrganisationOnboardingItem item) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _contextPills(item),
    );
    final Widget? actions = _orgActionsMenu(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                pills,
                if (actions != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: pills),
                if (actions != null) ...<Widget>[
                  const SizedBox(width: 8),
                  actions,
                ],
              ],
            ),
    );
  }

  List<Widget> _contextPills(OrganisationOnboardingItem item) {
    final OrganizationModel org = item.organization;
    final String code = item.organisationCode;
    return <Widget>[
      OrganizationThumbnail(organization: org, size: 28),
      if (code.isNotEmpty) OrganisationMetaChip(icon: AppIcons.key, label: code),
      OnboardingStatusPill(status: item.status, compact: true),
      OrganisationAccessChip(active: org.status == OrganizationAccessStatus.active, label: org.status.label),
      OrganisationMetaChip(icon: AppIcons.payments, label: org.commercialPlan.label),
      OrganisationMetaChip(
        icon: AppIcons.event,
        label: organisationCommercialUsabilityLabel(org),
      ),
    ];
  }

  Widget? _orgActionsMenu(OrganisationOnboardingItem item) {
    final List<CardOverflowMenuAction> actions = <CardOverflowMenuAction>[
      const CardOverflowMenuAction(value: 'edit', icon: AppIcons.edit, label: 'Edit organisation'),
      if (!item.isComplete)
        const CardOverflowMenuAction(value: 'continue', icon: AppIcons.onboardingNext, label: 'Continue setup'),
      if (item.isComplete)
        const CardOverflowMenuAction(value: 'test', icon: AppIcons.verification, label: 'Test workspace'),
      const CardOverflowMenuAction(value: 'delete', icon: AppIcons.delete, label: 'Delete', danger: true),
    ];
    return CardOverflowMenuButton(
      tooltip: 'Organisation actions',
      dividersBefore: const <String>{'delete'},
      actions: actions,
      onSelected: (String value) async {
        switch (value) {
          case 'edit':
            await OrganisationOnboardingActions.editOrganisation(context, item, onChanged: _notifyChanged);
          case 'continue':
            await OrganisationOnboardingActions.continueSetup(context, item, onChanged: _notifyChanged);
          case 'test':
            await OrganisationOnboardingActions.testConnection(context, item);
          case 'delete':
            await _handleDelete(item);
        }
      },
    );
  }

  Widget _tabbedBody(OrganisationOnboardingItem item) {
    return RichTabs(
      useSwitcherOnMobile: false,
      isScrollable: ResponsiveHelper.isMobile(context),
      tabs: const <RichTabItem>[
        RichTabItem('Overview', icon: AppIcons.organizations),
        RichTabItem('Commercial', icon: AppIcons.payments),
        RichTabItem('Setup & Provisioning', icon: AppIcons.verification),
      ],
      children: <Widget>[
        _OverviewTab(item: item, hackzOrgAdmin: _hackzOrgAdmin, onChanged: _notifyChanged),
        _CommercialTab(item: item, onChanged: _notifyChanged),
        _SetupTab(item: item, onChanged: _notifyChanged),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.item,
    required this.hackzOrgAdmin,
    required this.onChanged,
  });

  final OrganisationOnboardingItem item;
  final HkzOrgAdmin? hackzOrgAdmin;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final OrganizationModel org = item.organization;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionCard(
            title: 'Organisation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _infoRow('Name', org.name),
                _infoRow('Type', org.type.displayName),
                _infoRow('Address', org.address),
                _infoRow('Website', org.website),
                _infoRow('Contact', org.contact),
                const SizedBox(height: 12),
                OrganisationCodeRow(code: item.organisationCode),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Access summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OrganisationAccessChip(
                      active: org.status == OrganizationAccessStatus.active,
                      label: org.status.label,
                    ),
                    OrganisationMetaChip(icon: AppIcons.payments, label: org.commercialPlan.label),
                    if (org.commercialPlan.isTimeBound)
                      OrganisationMetaChip(icon: AppIcons.event, label: organisationValidityLabel(org)),
                    OrganisationMetaChip(
                      icon: OrganisationAccess.isGranted(org) ? AppIcons.workflowApproved : AppIcons.lock,
                      label: organisationCommercialUsabilityLabel(org),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Administrators',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OrganisationAdminRow(
                  label: 'College administrator',
                  admin: item.collegeAdmin,
                  icon: AppIcons.adminProfile,
                  showAdd: !item.isComplete && !item.initialAdminConfigured,
                  onAdd: () => OrganisationOnboardingActions.continueSetup(context, item, onChanged: onChanged),
                ),
                const SizedBox(height: 12),
                if (item.hackzOrgAdminConfigured)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(AppIcons.helpSupport, size: 16, color: Color(0xFF334155)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Hackz org admin',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                            ),
                            Text(
                              hackzOrgAdmin?.displayName.trim().isNotEmpty == true
                                  ? hackzOrgAdmin!.displayName
                                  : 'Assigned (support user)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  OrganisationAdminRow(
                    label: 'Hackz org admin',
                    admin: null,
                    icon: AppIcons.helpSupport,
                    showAdd: !item.isComplete,
                    onAdd: () => OrganisationOnboardingActions.continueSetup(context, item, onChanged: onChanged),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommercialTab extends StatelessWidget {
  const _CommercialTab({required this.item, required this.onChanged});

  final OrganisationOnboardingItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final OrganizationCommercialPlan plan = item.organization.commercialPlan;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OrganisationAccessControl(
            organization: item.organization,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          if (plan == OrganizationCommercialPlan.perIdea)
            _sectionCard(
              title: 'Per-idea commercial access',
              child: const Text(
                'Participation is validated through individual idea payments in the organisation tenant. '
                'Hackz does not mirror tenant payment transactions on the Control Plane.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
              ),
            ),
          if (plan != OrganizationCommercialPlan.perIdea) ...<Widget>[
            const SizedBox(height: 12),
            OrganisationEventCommercialAccess(
              key: ValueKey<String>(item.organization.id),
              item: item,
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupTab extends StatelessWidget {
  const _SetupTab({required this.item, required this.onChanged});

  final OrganisationOnboardingItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final double progress = item.completedSteps / OrganisationOnboardingStep.total;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _sectionCard(
            title: 'Tenant connection',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                WorkspaceConnectionPill(
                  label: item.firebaseStatusLabel,
                  ready: item.firebaseValidated && item.firebaseConnected,
                  connected: item.firebaseConnected,
                ),
                if ((item.tenant?.firebaseProjectId ?? '').trim().isNotEmpty)
                  OrganisationMetaChip(
                    icon: AppIcons.link,
                    label: item.tenant!.firebaseProjectId.trim(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Provisioning authorization',
            child: ProvisioningAuthorizationPanel(
              status: item.tenant?.provisioningAuthorization ?? ProvisioningAuthorizationStatus.required,
              lastValidatedAt: item.tenant?.provisioningAuthorizationValidatedAt,
              onValidateAgain: item.firebaseConnected
                  ? () => OrganisationOnboardingActions.validateAuthorization(
                        context,
                        item,
                        onChanged: onChanged,
                      )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Setup readiness',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OnboardingReadinessChecklist(item: item),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text(
                      '${item.completedSteps} of ${OrganisationOnboardingStep.total}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.isComplete ? 'Ready to use Hackz' : 'Next: ${item.nextStep.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: item.isComplete ? const Color(0xFF10B981) : const Color(0xFF6A38FF),
                  ),
                ),
                if (!item.isComplete) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () =>
                          OrganisationOnboardingActions.continueSetup(context, item, onChanged: onChanged),
                      icon: const Icon(AppIcons.onboardingNext, size: 16),
                      label: const Text('Continue setup'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6A38FF),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
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
}

Widget _sectionCard({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: kDashboardCardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: DashboardCardTitleStyle.textStyle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _infoRow(String label, String value) {
  final String text = value.trim();
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
        ),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    ),
  );
}
