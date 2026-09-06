import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_record.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/sysadmin/onboarding/models/organisation_onboarding_item.dart';
import 'package:hackz/features/sysadmin/onboarding/widgets/onboarding_readiness_checklist.dart';

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

  testWidgets('shows connected authorization administrator and ready checks', (WidgetTester tester) async {
    final OrganisationOnboardingItem item = OrganisationOnboardingItem(
      organization: org(),
      tenant: TenantRecord(
        tenantId: 't1',
        organisationCode: 'HKZ-S7K4PM',
        organisationName: 'Alpha College',
        firebaseProjectId: 'hackz-a17b6',
        status: TenantStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        organisationId: 'org-1',
        firebaseValidated: true,
        initialAdminConfigured: true,
        provisioningAuthorization: ProvisioningAuthorizationStatus.verified,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OnboardingReadinessChecklist(item: item)),
      ),
    );

    expect(find.text('Firebase Connected  ✓'), findsOneWidget);
    expect(find.text('College Authorization  ✓'), findsOneWidget);
    expect(find.text('Initial Administrator  ✓'), findsOneWidget);
    expect(find.text('Organisation Ready  ✓'), findsOneWidget);
  });
}
