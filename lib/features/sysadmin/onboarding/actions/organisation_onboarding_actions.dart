import 'package:flutter/material.dart';

import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/tenant_connection_exception.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import '../../../../core/firebase/tenant_record.dart' show ProvisioningAuthorizationStatus, TenantRecord;
import '../../../../core/firebase/tenant_registry.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/loading/hkz_async_loader.dart';
import '../../../../features/dashboard/sysadmin/screens/organization_dialog.dart';
import '../../../../utils/firestore_utils.dart';
import '../../org_admin/services/hkz_org_admin_service.dart';
import '../models/organisation_onboarding_item.dart';
import '../screens/add_organisation_wizard.dart';
import '../services/organisation_onboarding_service.dart';

abstract final class OrganisationOnboardingActions {
  OrganisationOnboardingActions._();

  static Future<void> testConnection(BuildContext context, OrganisationOnboardingItem item) async {
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

  static Future<void> validateAuthorization(
    BuildContext context,
    OrganisationOnboardingItem item, {
    required VoidCallback onChanged,
  }) async {
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

  static Future<void> continueSetup(
    BuildContext context,
    OrganisationOnboardingItem item, {
    required VoidCallback onChanged,
  }) async {
    final bool changed = await showAddOrganisationWizard(context: context, item: item);
    if (changed) onChanged();
  }

  static Future<void> editOrganisation(
    BuildContext context,
    OrganisationOnboardingItem item, {
    required VoidCallback onChanged,
  }) async {
    final bool saved = await showOrganizationDialog(
      context: context,
      initialOrganization: item.organization,
    );
    if (saved) onChanged();
  }

  static Future<bool> deleteOrganisation(
    BuildContext context,
    OrganisationOnboardingItem item, {
    required VoidCallback onChanged,
  }) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete organization?',
      message: 'This will permanently remove "${item.name}".',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return false;
    try {
      await HkzOrgAdminService.purgeOrganisationFromAllAdmins(item.organization.id);
      await TenantRegistry.onOrganisationDeleted(
        organisationId: item.organization.id,
        organisationName: item.name,
      );
      await FirestoreUtils.deleteOrganization(
        item.organization.id,
        database: HackzFirebase.controlPlane.firestore,
      );
      if (context.mounted) {
        FeedbackService.showSuccess(
          context,
          title: 'Deleted',
          message: '${item.name} was removed',
        );
        onChanged();
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        FeedbackService.showError(context, title: 'Delete failed', message: '$e');
      }
      return false;
    }
  }
}
