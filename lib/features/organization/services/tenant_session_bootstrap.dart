import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../utils/firestore_utils.dart';
import '../../app_metadata/services/app_metadata_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../models/organization_model.dart';
import 'organisation_access.dart';

/// Best-effort tenant setup on first organisation login (College Admin, etc.).
abstract final class TenantSessionBootstrap {
  TenantSessionBootstrap._();

  static Future<void> ensureForOrganisation(String orgId) async {
    if (!HackzFirebase.isOrganisationWorkspace) return;
    final String id = orgId.trim();
    if (id.isEmpty) return;

    await Future.wait(<Future<void>>[
      OrgSettingsService.seedFor(id),
      AppMetadataService.ensureSeeded(),
      _mirrorOrganizationCatalog(id),
    ]);
  }

  /// Copies Control Plane organisation catalog fields into tenant `hkzOrganizations`.
  static Future<void> _mirrorOrganizationCatalog(String orgId) async {
    final OrganizationModel? cpOrg = await OrganisationAccess.fetch(orgId);
    if (cpOrg == null) return;
    try {
      final Map<String, dynamic> payload = cpOrg.toCatalogMap();
      // Control Plane catalog often has no logo; empty strings would erase tenant uploads.
      if (((cpOrg.photoUrl ?? '').trim()).isEmpty) payload.remove('photoUrl');
      if (((cpOrg.thumbnailUrl ?? '').trim()).isEmpty) payload.remove('thumbnailUrl');
      await HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzOrganizations)
          .doc(orgId)
          .set(payload, SetOptions(merge: true));
    } catch (_) {
      // Tenant write may fail until rules allow; dashboard falls back to user fields.
    }
  }
}
