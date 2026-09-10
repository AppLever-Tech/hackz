import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/organization/models/enums/organization_access_mode.dart';
import 'package:hackz/features/organization/models/enums/organization_access_status.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/organization/services/organisation_access.dart';

void main() {
  OrganizationModel org({
    OrganizationAccessStatus status = OrganizationAccessStatus.active,
    OrganizationAccessMode accessMode = OrganizationAccessMode.perIdea,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    return OrganizationModel(
      id: 'org-1',
      name: 'Alpha College',
      type: OrganizationType.college,
      address: '1 Road',
      website: 'https://alpha.edu',
      contact: '999',
      createdAt: DateTime.utc(2026, 1, 1),
      status: status,
      accessMode: accessMode,
      validFrom: validFrom,
      validUntil: validUntil,
    );
  }

  test('inactive organisations are not granted access', () {
    expect(
      OrganisationAccess.isGranted(org(status: OrganizationAccessStatus.inactive)),
      isFalse,
    );
  });

  test('per-idea and per-event access do not require a validity window', () {
    expect(OrganisationAccess.isGranted(org()), isTrue);
    expect(
      OrganisationAccess.isGranted(org(accessMode: OrganizationAccessMode.perEvent)),
      isTrue,
    );
  });

  test('subscription is granted only inside validFrom/validUntil', () {
    final OrganizationModel subscription = org(
      accessMode: OrganizationAccessMode.subscription,
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 12, 31),
    );
    expect(OrganisationAccess.isGranted(subscription, now: DateTime(2026, 6, 1)), isTrue);
    expect(OrganisationAccess.isGranted(subscription, now: DateTime(2025, 12, 31)), isFalse);
    expect(OrganisationAccess.isGranted(subscription, now: DateTime(2027, 1, 1)), isFalse);
  });

  test('subscription without a window behaves as inactive', () {
    expect(
      OrganisationAccess.isGranted(org(accessMode: OrganizationAccessMode.subscription)),
      isFalse,
    );
  });

  test('registry maps persist commercial access fields', () {
    final OrganizationModel source = org(
      status: OrganizationAccessStatus.inactive,
      accessMode: OrganizationAccessMode.subscription,
      validFrom: DateTime.utc(2026, 3, 1),
      validUntil: DateTime.utc(2026, 9, 1),
    );
    final OrganizationModel parsed = OrganizationModel.fromMap('org-1', source.toMap());
    expect(parsed.status, OrganizationAccessStatus.inactive);
    expect(parsed.accessMode, OrganizationAccessMode.subscription);
    expect(parsed.validFrom!.year, 2026);
    expect(parsed.validFrom!.month, 3);
    expect(parsed.validFrom!.day, 1);
    expect(parsed.validUntil!.year, 2026);
    expect(parsed.validUntil!.month, 9);
    expect(parsed.validUntil!.day, 1);
    expect(parsed.toCatalogMap().containsKey('status'), isFalse);
  });
}
