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

  test('ProvisioningAuthorizationStatus parses registry values', () {
    expect(ProvisioningAuthorizationStatus.fromWire('pending'), ProvisioningAuthorizationStatus.pending);
    expect(ProvisioningAuthorizationStatus.fromWire('authorized'), ProvisioningAuthorizationStatus.verified);
    expect(ProvisioningAuthorizationStatus.fromWire('verified')?.isAuthorized, isTrue);
    expect(ProvisioningAuthorizationStatus.required.label, 'Pending');
    expect(ProvisioningAuthorizationStatus.pending.label, 'Pending');
    expect(ProvisioningAuthorizationStatus.verified.label, 'Authorized');
    expect(ProvisioningAuthorizationStatus.revoked.label, 'Revoked');
    expect(
      ProvisioningAuthorizationStatus.fromRegistry(raw: null, tenantStatus: TenantStatus.active),
      ProvisioningAuthorizationStatus.verified,
    );
    expect(
      ProvisioningAuthorizationStatus.fromRegistry(raw: null, tenantStatus: TenantStatus.setup),
      ProvisioningAuthorizationStatus.required,
    );
  });

  test('TenantRecord round-trips last authorization validation time', () {
    final DateTime at = DateTime.utc(2026, 9, 6, 4, 30);
    final TenantRecord record = TenantRecord(
      tenantId: 't1',
      organisationCode: 'HKZ-S7K4PM',
      organisationName: 'Alpha',
      firebaseProjectId: 'hackz-a17b6',
      status: TenantStatus.active,
      createdAt: DateTime.utc(2026, 1, 1),
      provisioningAuthorization: ProvisioningAuthorizationStatus.verified,
      provisioningAuthorizationValidatedAt: at,
    );
    final TenantRecord parsed = TenantRecord.fromMap(record.toMap());
    expect(parsed.provisioningAuthorization.isAuthorized, isTrue);
    expect(parsed.provisioningAuthorizationValidatedAt?.millisecondsSinceEpoch, at.millisecondsSinceEpoch);
  });

  test('uniqueCodesByOrganisationName keeps one non-inactive tenant per name', () {
    final Map<String, String> codes = TenantRegistry.uniqueCodesByOrganisationName(<TenantRecord>[
      tenant(name: 'Alpha', code: 'HKZ-S7K4PM'),
      tenant(name: 'Pending', code: '', status: TenantStatus.setup),
      tenant(name: 'Gone', code: 'HKZ-ZZZZZZ', status: TenantStatus.inactive),
      tenant(name: 'Dup', code: 'HKZ-AAA222'),
      tenant(name: 'Dup', code: 'HKZ-BBB333'),
    ]);
    expect(codes['Alpha'], 'HKZ-S7K4PM');
    expect(codes.containsKey('Pending'), isFalse);
    expect(codes.containsKey('Gone'), isFalse);
    expect(codes.containsKey('Dup'), isFalse);
  });
}
