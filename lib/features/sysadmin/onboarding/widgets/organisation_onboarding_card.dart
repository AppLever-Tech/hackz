import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_connection_exception.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import '../../../../core/firebase/tenant_registry.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/loading/hkz_loading_overlay.dart';
import '../../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../../features/dashboard/sysadmin/screens/organization_dialog.dart';
import '../../../../features/org_settings/services/org_settings_service.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../organization/widgets/organization_thumbnail.dart';
import '../../../user/models/user_model.dart';
import '../../../user/screens/create_user_dialog.dart';
import '../models/organisation_onboarding_item.dart';
import '../screens/add_organisation_wizard.dart';
import '../services/organisation_onboarding_service.dart';
import 'copy_organisation_code_button.dart';
import 'onboarding_status_pill.dart';

class OrganisationOnboardingCard extends StatelessWidget {
  const OrganisationOnboardingCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  final OrganisationOnboardingItem item;
  final VoidCallback onChanged;

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
              'Connected to ${probe.projectId}. Sign-in, data, and files resolved to this organisation.',
        );
        return;
      }
      await FeedbackService.showError(
        context,
        title: 'Workspace check failed',
        message:
            'Project ${probe.projectId}. Sign-in: ${probe.authOk ? 'ready' : 'failed'}. Data: ${probe.firestoreOk ? 'ready' : 'failed'}. Files: ${probe.storageOk ? 'ready' : 'failed'}.',
      );
    } on TenantConnectionException catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to connect', message: e.message);
    } catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to connect', message: '$e');
    }
  }

  Future<void> _openOrganisation(BuildContext context) async {
    final String? tenantId = item.tenant?.tenantId;
    if (tenantId == null || tenantId.isEmpty || !item.isComplete) return;
    try {
      HkzLoadingOverlay.show(
        context,
        title: 'Opening organisation',
        message: item.name,
      );
      await TenantFirebase.enterAsPlatformAdmin(tenantId);
      OrgSettingsService.instance.clearCache();
      if (!context.mounted) return;
      HkzLoadingOverlay.hide();
    } on TenantConnectionException catch (e) {
      HkzLoadingOverlay.hide();
      if (!context.mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Unable to open organisation',
        message: e.message,
      );
    } catch (e) {
      HkzLoadingOverlay.hide();
      if (!context.mounted) return;
      await FeedbackService.showError(
        context,
        title: 'Unable to open organisation',
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
    final bool assigned = await showCreateUserDialog(
      context: context,
      roleCode: 'CADM',
      organization: item.organization,
    );
    if (!assigned) return;
    final String? tenantId = item.tenant?.tenantId;
    if (tenantId != null && tenantId.isNotEmpty) {
      await OrganisationOnboardingService.markAdministratorReady(tenantId);
    }
    onChanged();
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
      await FirestoreUtils.deleteOrganization(item.organization.id);
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
          DashboardCardTitleBand(
            title: item.name,
            leading: OrganizationThumbnail(organization: item.organization, size: 32),
            trailing: Row(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OnboardingStatusPill(status: item.status),
                    WorkspaceConnectionPill(
                      label: item.firebaseStatusLabel,
                      ready: item.firebaseValidated && item.firebaseConnected,
                      connected: item.firebaseConnected,
                    ),
                    _MetaChip(
                      icon: AppIcons.orgType,
                      label: item.organization.type.displayName,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CodeRow(code: code),
                const SizedBox(height: 12),
                _AdminRow(
                  admin: admin,
                  onAdd: () => _assignAdmin(context),
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
                if (item.isComplete) ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => _openOrganisation(context),
                      icon: const Icon(AppIcons.openInNew, size: 16),
                      label: const Text('Open organisation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6A38FF),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
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
  const _AdminRow({required this.admin, required this.onAdd});

  final UserModel? admin;
  final VoidCallback onAdd;

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
        if (user == null)
          TextButton(
            onPressed: onAdd,
            child: const Text('Add'),
          ),
      ],
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
