import '../../../core/firebase/hackz_firebase.dart';
import '../../../utils/firestore_utils.dart';
import '../models/enums/organization_access_mode.dart';
import '../models/enums/organization_access_status.dart';
import '../models/organization_model.dart';

/// Control Plane commercial-access check for an organisation.
///
/// Reads `hkzOrganizations` on [HackzFirebase.controlPlane] only. Tenant
/// features should call this instead of inspecting tenant Firestore.
abstract final class OrganisationAccess {
  OrganisationAccess._();

  static const String inactiveMessage = 'This organisation does not currently have Hackz access.';

  static OrganizationModel? _cached;
  static String? _cachedOrgId;

  /// Effective access right now. Expired subscriptions are treated as inactive.
  static bool isGranted(OrganizationModel org, {DateTime? now}) {
    if (org.status != OrganizationAccessStatus.active) return false;
    if (org.accessMode != OrganizationAccessMode.subscription) return true;
    final DateTime? from = org.validFrom;
    final DateTime? until = org.validUntil;
    if (from == null || until == null) return false;
    final DateTime at = now ?? DateTime.now();
    final DateTime day = DateTime(at.year, at.month, at.day);
    final DateTime start = DateTime(from.year, from.month, from.day);
    final DateTime end = DateTime(until.year, until.month, until.day);
    if (end.isBefore(start)) return false;
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// Loads the Control Plane registry row and evaluates [isGranted].
  static Future<bool> isGrantedForOrgId(String orgId, {DateTime? now}) async {
    final OrganizationModel? org = await fetch(orgId);
    if (org == null) return false;
    return isGranted(org, now: now);
  }

  static Future<OrganizationModel?> fetch(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return null;
    if (_cachedOrgId == id) return _cached;
    final OrganizationModel? org = await FirestoreUtils.fetchOrganization(
      id,
      database: HackzFirebase.controlPlane.firestore,
    );
    _cached = org;
    _cachedOrgId = id;
    return org;
  }

  /// `true` / `false` when Control Plane access mode is known; `null` on miss.
  static Future<bool?> isPerEvent(String orgId) async {
    try {
      final OrganizationModel? org = await fetch(orgId);
      if (org == null) return null;
      return org.accessMode == OrganizationAccessMode.perEvent;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _cached = null;
    _cachedOrgId = null;
  }
}
