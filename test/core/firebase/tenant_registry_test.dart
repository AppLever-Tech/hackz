import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_record.dart';
import 'package:hackz/core/firebase/tenant_registry.dart';

void main() {
  TenantRecord tenant({
    required String name,
    required String code,
    TenantStatus status = TenantStatus.active,
  }) {
    return TenantRecord(
      tenantId: 't-$code',
      organisationCode: code,
      organisationName: name,
      firebaseProjectId: 'hackz-a17b6',
      status: status,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('TenantStatus parses wire values', () {
    expect(TenantStatus.fromWire('active'), TenantStatus.active);
    expect(TenantStatus.fromWire('SETUP'), TenantStatus.setup);
    expect(TenantStatus.fromWire('inactive'), TenantStatus.inactive);
    expect(TenantStatus.fromWire('nope'), isNull);
  });

  test('uniqueCodesByOrganisationName keeps one non-inactive tenant per name', () {
    final Map<String, String> codes = TenantRegistry.uniqueCodesByOrganisationName(<TenantRecord>[
      tenant(name: 'Alpha', code: 'HKZ-S7K4PM'),
      tenant(name: 'Beta', code: 'HKZ-AB3DEF', status: TenantStatus.setup),
      tenant(name: 'Gone', code: 'HKZ-ZZZZZZ', status: TenantStatus.inactive),
      tenant(name: 'Dup', code: 'HKZ-AAA222'),
      tenant(name: 'Dup', code: 'HKZ-BBB333'),
    ]);
    expect(codes['Alpha'], 'HKZ-S7K4PM');
    expect(codes['Beta'], 'HKZ-AB3DEF');
    expect(codes.containsKey('Gone'), isFalse);
    expect(codes.containsKey('Dup'), isFalse);
  });
}
