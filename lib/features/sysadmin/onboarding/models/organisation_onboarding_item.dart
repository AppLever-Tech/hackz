import '../../../../core/firebase/organisation_code.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../organization/models/organization_model.dart';
import '../../../user/models/user_model.dart';

enum OrganisationOnboardingStep {
  organisation,
  firebase,
  validate,
  hackzSetup,
  initialAdmin,
  activate;

  String get label {
    switch (this) {
      case OrganisationOnboardingStep.organisation:
        return 'Organisation';
      case OrganisationOnboardingStep.firebase:
        return 'Workspace';
      case OrganisationOnboardingStep.validate:
        return 'Checks';
      case OrganisationOnboardingStep.hackzSetup:
        return 'Hackz setup';
      case OrganisationOnboardingStep.initialAdmin:
        return 'Administrator';
      case OrganisationOnboardingStep.activate:
        return 'Activate';
    }
  }

  static const int total = 6;
}

class OrganisationOnboardingItem {
  const OrganisationOnboardingItem({
    required this.organization,
    this.tenant,
    this.collegeAdmin,
    this.settingsSeeded = false,
  });

  final OrganizationModel organization;
  final TenantRecord? tenant;
  final UserModel? collegeAdmin;
  final bool settingsSeeded;

  String get name => organization.name;

  String get organisationCode {
    final String code = (tenant?.organisationCode ?? '').trim();
    return OrganisationCode.isValid(code) ? code : '';
  }

  TenantStatus get status => tenant?.status ?? TenantStatus.setup;

  bool get firebaseConnected => (tenant?.firebaseProjectId ?? '').trim().isNotEmpty;

  bool get firebaseValidated => tenant?.firebaseValidated ?? false;

  bool get hackzSetupComplete => (tenant?.hackzSetupComplete ?? false) || settingsSeeded;

  bool get initialAdminConfigured =>
      (tenant?.initialAdminConfigured ?? false) || collegeAdmin != null;

  bool get isActivated =>
      status == TenantStatus.active && organisationCode.isNotEmpty;

  bool get organisationReady => organization.id.trim().isNotEmpty;

  bool get isComplete => isActivated;

  int get completedSteps {
    int count = 0;
    if (organisationReady) count++;
    if (firebaseConnected) count++;
    if (firebaseValidated) count++;
    if (hackzSetupComplete) count++;
    if (initialAdminConfigured) count++;
    if (isActivated) count++;
    return count;
  }

  OrganisationOnboardingStep get nextStep {
    if (!organisationReady || tenant == null) return OrganisationOnboardingStep.organisation;
    if (!firebaseConnected) return OrganisationOnboardingStep.firebase;
    if (!firebaseValidated) return OrganisationOnboardingStep.validate;
    if (!hackzSetupComplete) return OrganisationOnboardingStep.hackzSetup;
    if (!initialAdminConfigured) return OrganisationOnboardingStep.initialAdmin;
    if (!isActivated) return OrganisationOnboardingStep.activate;
    return OrganisationOnboardingStep.activate;
  }

  String get firebaseStatusLabel {
    if (firebaseValidated && firebaseConnected) return 'Ready';
    if (firebaseConnected) return 'Connected';
    return 'Not connected';
  }
}
