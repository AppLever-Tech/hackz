import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_record.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/sysadmin/onboarding/models/organisation_onboarding_item.dart';

void main() {
  OrganizationModel org() {
    return OrganizationModel(
      id: 'org-1',
      name: 'Alpha College',
      type: OrganizationType.college,
      address: '1 Road',
      website: 'https://alpha.edu',
      contact: '999',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  TenantRecord tenant({
    TenantStatus status = TenantStatus.setup,
    String code = '',
    String projectId = '',
    bool validated = false,
    bool setup = false,
    bool admin = false,
  }) {
    return TenantRecord(
      tenantId: 't1',
      organisationCode: code,
      organisationName: 'Alpha College',
      firebaseProjectId: projectId,
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
      organisationId: 'org-1',
      firebaseValidated: validated,
      hackzSetupComplete: setup,
      initialAdminConfigured: admin,
    );
  }

  test('progress starts at organisation when tenant is missing', () {
    final OrganisationOnboardingItem item = OrganisationOnboardingItem(organization: org());
    expect(item.completedSteps, 1);
    expect(item.nextStep, OrganisationOnboardingStep.organisation);
    expect(item.firebaseStatusLabel, 'Not connected');
    expect(item.organisationCode, isEmpty);
  });

  test('activate is next only after admin and checks', () {
    final OrganisationOnboardingItem item = OrganisationOnboardingItem(
      organization: org(),
      tenant: tenant(
        projectId: 'hackz-a17b6',
        validated: true,
        setup: true,
        admin: true,
      ),
    );
    expect(item.completedSteps, 5);
    expect(item.nextStep, OrganisationOnboardingStep.activate);
    expect(item.isComplete, isFalse);
  });

  test('active tenant with code is complete', () {
    final OrganisationOnboardingItem item = OrganisationOnboardingItem(
      organization: org(),
      tenant: tenant(
        status: TenantStatus.active,
        code: 'HKZ-S7K4PM',
        projectId: 'hackz-a17b6',
        validated: true,
        setup: true,
        admin: true,
      ),
    );
    expect(item.isComplete, isTrue);
    expect(item.completedSteps, 6);
    expect(item.organisationCode, 'HKZ-S7K4PM');
    expect(item.firebaseStatusLabel, 'Ready');
  });
}
