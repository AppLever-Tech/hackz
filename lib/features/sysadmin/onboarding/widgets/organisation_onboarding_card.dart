import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_connection_exception.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/firebase/tenant_registry.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/loading/hkz_async_loader.dart';
import '../../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../../features/dashboard/sysadmin/screens/organization_dialog.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../organization/models/enums/organization_access_status.dart';
import '../../../organization/models/organization_model.dart';
import '../../../organization/services/organisation_access.dart';
import '../../../organization/widgets/organization_thumbnail.dart';
import '../../../user/models/user_model.dart';
import '../../org_admin/services/hkz_org_admin_service.dart';
import '../models/organisation_onboarding_item.dart';
import '../screens/add_organisation_wizard.dart';
import '../services/organisation_onboarding_service.dart';
import 'copy_organisation_code_button.dart';
import 'onboarding_readiness_checklist.dart';
import 'onboarding_status_pill.dart';
import 'organisation_access_control.dart';
import 'organisation_event_commercial_access.dart';
import 'provisioning_authorization_panel.dart';

class OrganisationOnboardingCard extends StatefulWidget {
  const OrganisationOnboardingCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  final OrganisationOnboardingItem item;
  final VoidCallback onChanged;

  @override
  State<OrganisationOnboardingCard> createState() => _OrganisationOnboardingCardState();
}

class _OrganisationOnboardingCardState extends State<OrganisationOnboardingCard> {
  bool _expanded = false;

  OrganisationOnboardingItem get item => widget.item;
  VoidCallback get onChanged => widget.onChanged;

  Future<void> _testConnection(BuildContext context) async {
    final String code = item.organisationCode;
    if (code.isEmpty) return;
    try {
      final TenantWorkspaceProbe probe = await TenantFirebase.probe(code);
      if (!context.mounted) return;
      if (probe.ok) {
        await FeedbackService.showSuccess(
          context,
          title: 'Workspace ready',
          message:
              'Connected to ${probe.projectId}. Sign-in and workspace data are reachable for this organisation.',
        );
        return;
      }
      await FeedbackService.showError(
        context,
        title: 'Workspace check failed',
        message:
            'Project ${probe.projectId}. Sign-in: ${probe.authOk ? 'ready' : 'failed'}. '
            'Data: ${probe.firestoreOk ? 'ready' : 'failed'}.'
            '${probe.storageOk ? '' : ' File storage is not configured (optional until logos or payment proofs are used).'}',
      );
    } on TenantConnectionException catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to connect', message: e.message);
    } catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to connect', message: '$e');
    }
  }

  Future<void> _validateAuthorization(BuildContext context) async {
    final TenantRecord? tenant = item.tenant;
    if (tenant == null || tenant.firebaseProjectId.trim().isEmpty) return;
    try {
      await HkzAsyncLoader.run<TenantRecord>(
        context,
        title: 'Validate authorization',
        message: 'Checking provisioning access...',
        successMessage: ProvisioningAuthorizationStatus.verified.lifecycleMessage,
        successHold: const Duration(milliseconds: 900),
        task: () => OrganisationOnboardingService.revalidateProvisioningAuthorization(tenant),
      );
      onChanged();
    } catch (e) {
      onChanged();
      if (!context.mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Provisioning Authorization',
        message: '$e',
      );
    }
  }

  Future<void> _continue(BuildContext context) async {
    final bool changed = await showAddOrganisationWizard(context: context, item: item);
    if (changed) onChanged();
  }

  Future<void> _edit(BuildContext context) async {
    final bool saved = await showOrganizationDialog(
      context: context,
      initialOrganization: item.organization,
    );
    if (saved) onChanged();
  }

  Future<void> _assignAdmin(BuildContext context) async {
    if (item.isComplete) return;
    await _continue(context);
  }

  Future<void> _delete(BuildContext context) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete organization?',
      message: 'This will permanently remove "${item.name}".',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return;
    try {
      await HkzOrgAdminService.purgeOrganisationFromAllAdmins(item.organization.id);
      await FirestoreUtils.deleteOrganization(
        item.organization.id,
        database: HackzFirebase.controlPlane.firestore,
      );
      await TenantRegistry.inactivateByOrganisationId(item.organization.id);
      await TenantRegistry.inactivateByOrganisationName(item.name);
      if (context.mounted) {
        FeedbackService.showSuccess(
          context,
          title: 'Deleted',
          message: '${item.name} was removed',
        );
        onChanged();
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackService.showError(context, title: 'Delete failed', message: '$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String code = item.organisationCode;
    final UserModel? admin = item.collegeAdmin;
    final double progress = item.completedSteps / OrganisationOnboardingStep.total;

    return Container(
      width: double.infinity,
      decoration: kDashboardCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: DashboardCardTitleStyle.bandFill,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: _expanded
                      ? const BorderSide(color: DashboardCardTitleStyle.bandDivider)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: DashboardCardTitleStyle.bandPadding,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            OrganizationThumbnail(organization: item.organization, size: 32),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DashboardCardTitleStyle.textStyle,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: <Widget>[
                                      OnboardingStatusPill(status: item.status, compact: true),
                                      _AccessChip(
                                        active: item.organization.status == OrganizationAccessStatus.active,
                                        label: item.organization.status.label,
                                      ),
                                      _MetaChip(
                                        icon: AppIcons.payments,
                                        label: item.organization.commercialPlan.label,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 4),
                              child: Icon(
                                _expanded ? AppIcons.expandLess : AppIcons.expandMore,
                                size: 22,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (item.isComplete)
                          HoverIconActionButton(
                            icon: AppIcons.verification,
                            tooltip: 'Test workspace',
                            iconSize: 17,
                            onTap: () => _testConnection(context),
                          ),
                        if (!item.isComplete)
                          HoverIconActionButton(
                            icon: AppIcons.onboardingNext,
                            tooltip: 'Continue setup',
                            iconSize: 17,
                            onTap: () => _continue(context),
                          ),
                        HoverIconActionButton(
                          icon: AppIcons.edit,
                          tooltip: 'Edit organization',
                          iconSize: 17,
                          onTap: () => _edit(context),
                        ),
                        HoverIconActionButton(
                          icon: AppIcons.delete,
                          tooltip: 'Delete organization',
                          destructive: true,
                          iconSize: 17,
                          onTap: () => _delete(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      WorkspaceConnectionPill(
                        label: item.firebaseStatusLabel,
                        ready: item.firebaseValidated && item.firebaseConnected,
                        connected: item.firebaseConnected,
                      ),
                      _MetaChip(
                        icon: AppIcons.orgType,
                        label: item.organization.type.displayName,
                      ),
                      if (item.organization.commercialPlan.isTimeBound)
                        _MetaChip(
                          icon: AppIcons.event,
                          label: _validityLabel(item.organization),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CodeRow(code: code),
                  const SizedBox(height: 12),
                  OrganisationAccessControl(
                    organization: item.organization,
                    onChanged: onChanged,
                  ),
                  const SizedBox(height: 12),
                  OrganisationEventCommercialAccess(
                    key: ValueKey<String>(item.organization.id),
                    item: item,
                  ),
                  const SizedBox(height: 12),
                  ProvisioningAuthorizationPanel(
                    status: item.tenant?.provisioningAuthorization ??
                        ProvisioningAuthorizationStatus.required,
                    lastValidatedAt: item.tenant?.provisioningAuthorizationValidatedAt,
                    onValidateAgain: item.firebaseConnected
                        ? () => _validateAuthorization(context)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OnboardingReadinessChecklist(item: item),
                  const SizedBox(height: 12),
                  _AdminRow(
                    admin: admin,
                    onAdd: () => _assignAdmin(context),
                    showAdd: !item.isComplete && !item.initialAdminConfigured,
                  ),
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
                        onPressed: () => _continue(context),
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

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final bool hasCode = code.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.key, size: 16, color: hasCode ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Organisation code',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                Text(
                  hasCode ? code : 'Assigned at activation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: hasCode ? 0.6 : 0,
                    color: hasCode ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (hasCode) CopyOrganisationCodeButton(code: code),
        ],
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.admin,
    required this.onAdd,
    required this.showAdd,
  });

  final UserModel? admin;
  final VoidCallback onAdd;
  final bool showAdd;

  @override
  Widget build(BuildContext context) {
    final UserModel? user = admin;
    return Row(
      children: <Widget>[
        Icon(
          AppIcons.adminProfile,
          size: 16,
          color: user == null ? const Color(0xFF94A3B8) : const Color(0xFF334155),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            user == null ? 'Initial administrator not assigned' : userDisplayName(user),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: user == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            ),
          ),
        ),
        if (showAdd)
          TextButton(
            onPressed: onAdd,
            child: const Text('Add'),
          ),
      ],
    );
  }
}

String _validityLabel(OrganizationModel organization) {
  final DateTime? from = organization.validFrom;
  final DateTime? until = organization.validUntil;
  if (from == null || until == null) return 'Validity not set';
  return '${formatShortDate(from)} – ${formatShortDate(until)}';
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? const Color(0xFF047857) : const Color(0xFF64748B);
    final Color bg = active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(active ? AppIcons.workflowApproved : AppIcons.lock, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
