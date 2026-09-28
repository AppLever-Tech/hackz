import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_record.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/sysadmin/services/org_management_service.dart';

void main() {
  test('collegeAdminFromTenantRegistry builds display user from hkzTenants snapshot', () {
    final OrganizationModel org = OrganizationModel(
      id: 'org-1',
      name: 'Alpha College',
      type: OrganizationType.college,
      address: 'Addr',
      website: 'https://alpha.example',
      contact: 'contact@alpha.example',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final TenantRecord tenant = TenantRecord(
      tenantId: 't-1',
      organisationCode: 'HKZ-ABCDEF',
      organisationName: org.name,
      firebaseProjectId: 'tenant-project',
      status: TenantStatus.active,
      createdAt: DateTime.utc(2026, 1, 2),
      organisationId: org.id,
      initialAdminConfigured: true,
      initialCollegeAdminUserId: 'uid-1',
      initialCollegeAdminFirstName: 'Priya',
      initialCollegeAdminLastName: 'Sharma',
      initialCollegeAdminPhone: '+911234567890',
    );

    final user = OrgManagementService.collegeAdminFromTenantRegistry(
      organization: org,
      tenant: tenant,
    );

    expect(user, isNotNull);
    expect(user!.firstName, 'Priya');
    expect(user.lastName, 'Sharma');
    expect(user.userId, 'uid-1');
  });
}
