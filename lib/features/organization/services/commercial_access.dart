import '../../ideathons/models/event_commercial_access.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../models/organization_model.dart';
import 'organisation_access.dart';

/// Single commercial-policy entry point for the three supported models.
///
/// Per-idea: organisation grant + existing idea payments.
/// Per-event: organisation grant + event commercialAccess (activation).
/// Subscription: organisation grant (validFrom/validUntil) + events created enabled.
abstract final class CommercialAccess {
  CommercialAccess._();

  static const String organisationDeniedMessage = OrganisationAccess.inactiveMessage;
  static const String eventDisabledMessage =
      'This event does not currently have commercial access.';
  static const String eventNotLicensedMessage =
      'This event is not commercially enabled yet.';

  static bool isOrganisationOperational(OrganizationModel org, {DateTime? now}) {
    return OrganisationAccess.isGranted(org, now: now);
  }

  static Future<void> assertOrganisationOperational(String orgId) async {
    if (!await OrganisationAccess.isGrantedForOrgId(orgId)) {
      throw StateError(organisationDeniedMessage);
    }
  }

  /// Join, pay, and submit. Blocked only when SysAdmin has revoked event access.
  static bool allowsEventParticipation(IdeathonModel event) {
    return event.commercialAccess.allowsParticipation;
  }

  /// Evaluation and event completion require an enabled commercial flag.
  static bool isEventLicensed(IdeathonModel event) {
    return event.commercialAccess.isEnabled;
  }

  static Future<void> assertEventParticipation(IdeathonModel event) async {
    await assertOrganisationOperational(event.orgId);
    if (!allowsEventParticipation(event)) {
      throw StateError(eventDisabledMessage);
    }
  }

  static Future<void> assertEventLicensed(IdeathonModel event) async {
    await assertOrganisationOperational(event.orgId);
    if (!isEventLicensed(event)) {
      throw StateError(eventNotLicensedMessage);
    }
  }

  static EventCommercialAccess initialEventAccess({required bool perEvent}) {
    return perEvent ? EventCommercialAccess.pending : EventCommercialAccess.enabled;
  }
}
