import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/sysadmin/org_admin/models/hkz_org_admin.dart';
import 'package:hackz/features/user/models/enums/user_role.dart';

void main() {
  test('mergeOrganisationAssignments is idempotent', () {
    expect(
      HkzOrgAdmin.mergeOrganisationAssignments(<String>['org-a'], 'org-a'),
      <String>['org-a'],
    );
    expect(
      HkzOrgAdmin.mergeOrganisationAssignments(<String>['org-a'], 'org-b'),
      <String>['org-a', 'org-b'],
    );
    expect(
      HkzOrgAdmin.mergeOrganisationAssignments(<String>['org-a', 'org-b'], 'org-a'),
      <String>['org-a', 'org-b'],
    );
  });

  test('removeOrganisationAssignment drops one org', () {
    expect(
      HkzOrgAdmin.removeOrganisationAssignment(<String>['org-a', 'org-b'], 'org-a'),
      <String>['org-b'],
    );
  });

  test('orgAdmin role code is OADM', () {
    expect(UserRole.orgAdmin.code, 'OADM');
    expect(UserRole.isOrgAdminCode('oadm'), isTrue);
    expect(UserRole.isOrgAdminCode('CADM'), isFalse);
  });
}
