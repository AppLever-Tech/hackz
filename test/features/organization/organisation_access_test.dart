import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/organization/models/enums/organization_access_status.dart';
import 'package:hackz/features/organization/models/enums/organization_commercial_plan.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/organization/services/organisation_access.dart';

void main() {
  OrganizationModel org({
    OrganizationAccessStatus status = OrganizationAccessStatus.active,
    OrganizationCommercialPlan commercialPlan = OrganizationCommercialPlan.perIdea,
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
      commercialPlan: commercialPlan,
      validFrom: validFrom,
      validUntil: validUntil,
    );
  }

  test('inactive organisations are not commercially usable', () {
    expect(
      OrganisationAccess.isGranted(org(status: OrganizationAccessStatus.inactive)),
      isFalse,
    );
  });

  test('per-idea and per-event plans do not require a validity window', () {
    expect(OrganisationAccess.isGranted(org()), isTrue);
    expect(
      OrganisationAccess.isGranted(org(commercialPlan: OrganizationCommercialPlan.perEvent)),
      isTrue,
    );
  });

  test('annual is usable only inside validFrom/validUntil', () {
    final OrganizationModel annual = org(
      commercialPlan: OrganizationCommercialPlan.annual,
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 12, 31),
    );
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2026, 6, 1)), isTrue);
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2025, 12, 31)), isFalse);
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2027, 1, 1)), isFalse);
  });

  test('annual without a window is not commercially usable', () {
    expect(
      OrganisationAccess.isGranted(org(commercialPlan: OrganizationCommercialPlan.annual)),
      isFalse,
    );
  });

  test('active annual outside the window stays ACTIVE but is not usable', () {
    final OrganizationModel annual = org(
      status: OrganizationAccessStatus.active,
      commercialPlan: OrganizationCommercialPlan.annual,
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 12, 31),
    );
    expect(annual.status, OrganizationAccessStatus.active);
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2027, 1, 2)), isFalse);
  });

  test('annual grant uses the current date even when the org row was previously granted', () {
    final OrganizationModel annual = org(
      commercialPlan: OrganizationCommercialPlan.annual,
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 6, 30),
    );
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2026, 6, 30)), isTrue);
    expect(OrganisationAccess.isGranted(annual, now: DateTime(2026, 7, 1)), isFalse);
  });

  test('registry maps persist organisation status and commercial plan', () {
    final OrganizationModel source = org(
      status: OrganizationAccessStatus.inactive,
      commercialPlan: OrganizationCommercialPlan.annual,
      validFrom: DateTime.utc(2026, 3, 1),
      validUntil: DateTime.utc(2026, 9, 1),
    );
    final Map<String, dynamic> payload = source.toMap();
    expect(payload['commercialPlan'], OrganizationCommercialPlan.annual.wireValue);
    expect(payload.containsKey('accessMode'), isFalse);
    final OrganizationModel parsed = OrganizationModel.fromMap('org-1', payload);
    expect(parsed.status, OrganizationAccessStatus.inactive);
    expect(parsed.commercialPlan, OrganizationCommercialPlan.annual);
    expect(parsed.validFrom!.year, 2026);
    expect(parsed.validFrom!.month, 3);
    expect(parsed.validFrom!.day, 1);
    expect(parsed.validUntil!.year, 2026);
    expect(parsed.validUntil!.month, 9);
    expect(parsed.validUntil!.day, 1);
    expect(parsed.toCatalogMap().containsKey('status'), isFalse);
    expect(parsed.toCatalogMap().containsKey('commercialPlan'), isFalse);
  });

  test('fromMap reads existing accessMode values into commercialPlan', () {
    final OrganizationModel subscription = OrganizationModel.fromMap(
      'org-1',
      <String, dynamic>{
        'name': 'Alpha College',
        'accessMode': 'subscription',
        'status': 'active',
      },
    );
    expect(subscription.commercialPlan, OrganizationCommercialPlan.annual);

    final OrganizationModel perEvent = OrganizationModel.fromMap(
      'org-1',
      <String, dynamic>{
        'name': 'Alpha College',
        'accessMode': 'perEvent',
      },
    );
    expect(perEvent.commercialPlan, OrganizationCommercialPlan.perEvent);

    final OrganizationModel named = OrganizationModel.fromMap(
      'org-1',
      <String, dynamic>{
        'name': 'Alpha College',
        'commercialPlan': 'PER_IDEA',
        'accessMode': 'perEvent',
      },
    );
    expect(named.commercialPlan, OrganizationCommercialPlan.perIdea);
  });

  test('fromWire accepts PER_IDEA, PER_EVENT, ANNUAL and existing camelCase values', () {
    expect(
      OrganizationCommercialPlan.fromWire('PER_IDEA'),
      OrganizationCommercialPlan.perIdea,
    );
    expect(
      OrganizationCommercialPlan.fromWire('perIdea'),
      OrganizationCommercialPlan.perIdea,
    );
    expect(
      OrganizationCommercialPlan.fromWire('PER_EVENT'),
      OrganizationCommercialPlan.perEvent,
    );
    expect(
      OrganizationCommercialPlan.fromWire('perEvent'),
      OrganizationCommercialPlan.perEvent,
    );
    expect(
      OrganizationCommercialPlan.fromWire('ANNUAL'),
      OrganizationCommercialPlan.annual,
    );
    expect(
      OrganizationCommercialPlan.fromWire('subscription'),
      OrganizationCommercialPlan.annual,
    );
  });
}
