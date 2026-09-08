import 'package:hackz/core/firebase/hackz_firebase.dart';

import '../../user/models/user_model.dart';

/// Tenant isolation for exports. Role checks stay in each module provider.
abstract final class ExportTenantGuard {
  static void assertOrganisationWorkspace() {
    if (!HackzFirebase.isOrganisationWorkspace) {
      throw StateError('Export requires an organisation workspace.');
    }
  }

  /// True when the actor belongs to the bound organisation (or is viewing it
  /// as platform admin after a tenant rebind).
  static bool actorMatchesBoundOrganisation(UserModel actor) {
    if (!HackzFirebase.isOrganisationWorkspace) return false;
    final String tenantOrg = HackzFirebase.current.context.organisationId.trim();
    final String actorOrg = actor.orgId.trim();
    if (actorOrg.isNotEmpty && tenantOrg.isNotEmpty && actorOrg != tenantOrg) {
      return false;
    }
    return true;
  }

  static String boundOrganisationId() {
    return HackzFirebase.current.context.organisationId.trim();
  }
}
