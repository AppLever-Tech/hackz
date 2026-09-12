import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/ideathons/models/event_commercial_access.dart';
import 'package:hackz/features/ideathons/models/ideathon_idea_snapshot.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_status.dart';
import 'package:hackz/features/organization/models/enums/organization_commercial_plan.dart';
import 'package:hackz/features/organization/services/commercial_access.dart';

void main() {
  IdeathonModel event({EventCommercialAccess access = EventCommercialAccess.enabled}) {
    final DateTime now = DateTime.utc(2026, 6, 1);
    return IdeathonModel(
      ideathonId: 'evt1',
      orgId: 'org-1',
      name: 'Spring',
      description: '',
      departmentId: 'CSE',
      startDateTime: now,
      endDateTime: now.add(const Duration(days: 1)),
      status: IdeathonStatus.scheduled,
      judgeIds: const <String>[],
      coordinatorIds: const <String>[],
      ideas: const <IdeathonIdeaSnapshot>[],
      evaluationTemplateId: 't1',
      createdBy: 'u1',
      createdAt: now,
      updatedAt: now,
      commercialAccess: access,
    );
  }

  test('annual and per-idea events start commercially enabled', () {
    expect(CommercialAccess.initialEventAccess(perEvent: false).isEnabled, isTrue);
  });

  test('per-event events start pending activation', () {
    expect(CommercialAccess.initialEventAccess(perEvent: true).isPending, isTrue);
  });

  test('pending events allow participation but are not licensed', () {
    final IdeathonModel pending = event(access: EventCommercialAccess.pending);
    expect(CommercialAccess.allowsEventParticipation(pending), isTrue);
    expect(CommercialAccess.isEventLicensed(pending), isFalse);
  });

  test('enabled events allow participation and evaluation', () {
    final IdeathonModel enabled = event();
    expect(CommercialAccess.allowsEventParticipation(enabled), isTrue);
    expect(CommercialAccess.isEventLicensed(enabled), isTrue);
  });

  test('revoked events block participation and evaluation', () {
    final IdeathonModel revoked = event(access: EventCommercialAccess.disabled);
    expect(CommercialAccess.allowsEventParticipation(revoked), isFalse);
    expect(CommercialAccess.isEventLicensed(revoked), isFalse);
  });

  test('only per-idea requires individual idea payment', () {
    expect(CommercialAccess.requiresIdeaPayment(OrganizationCommercialPlan.perIdea), isTrue);
    expect(CommercialAccess.requiresIdeaPayment(OrganizationCommercialPlan.perEvent), isFalse);
    expect(CommercialAccess.requiresIdeaPayment(OrganizationCommercialPlan.annual), isFalse);
  });

  test('missing organisation defaults to per-idea so payments are not skipped', () {
    expect(CommercialAccess.planOf(null), OrganizationCommercialPlan.perIdea);
    expect(CommercialAccess.requiresIdeaPayment(CommercialAccess.planOf(null)), isTrue);
  });

  test('department admin indicator follows commercial plan and event access', () {
    expect(
      CommercialAccess.departmentAdminIndicator(
        plan: OrganizationCommercialPlan.perIdea,
        access: EventCommercialAccess.enabled,
      ),
      CommercialAccess.individualPaymentLabel,
    );
    expect(
      CommercialAccess.departmentAdminIndicator(
        plan: OrganizationCommercialPlan.perEvent,
        access: EventCommercialAccess.pending,
      ),
      CommercialAccess.activationPendingLabel,
    );
    expect(
      CommercialAccess.departmentAdminIndicator(
        plan: OrganizationCommercialPlan.perEvent,
        access: EventCommercialAccess.enabled,
      ),
      CommercialAccess.commercialAccessActiveLabel,
    );
    expect(
      CommercialAccess.departmentAdminIndicator(
        plan: OrganizationCommercialPlan.annual,
        access: EventCommercialAccess.enabled,
      ),
      CommercialAccess.annualContractLabel,
    );
    expect(
      CommercialAccess.departmentAdminIndicator(
        plan: OrganizationCommercialPlan.annual,
        access: EventCommercialAccess.disabled,
      ),
      CommercialAccess.accessDisabledLabel,
    );
  });
}
