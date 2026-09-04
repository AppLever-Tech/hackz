import 'package:cloud_firestore/cloud_firestore.dart';

import 'approved_tenant_firebase.dart';
import 'hackz_firebase.dart';
import 'organisation_code.dart';
import 'tenant_record.dart';

/// Control Plane tenant registry (`hkzTenants`).
///
/// Stores routing/onboarding metadata only. College Problems, Ideas, Teams,
/// Events, Payments, Users, Evaluations, and Storage stay in that organisation's
/// own Firebase project.
abstract final class TenantRegistry {
  TenantRegistry._();

  static const String collectionName = 'hkzTenants';
  static const int _maxCodeAttempts = 12;

  static FirebaseFirestore get _db => HackzFirebase.controlPlane.firestore;

  static CollectionReference<Map<String, dynamic>> get _col {
    return _db.collection(collectionName);
  }

  /// Starts Control Plane onboarding without assigning an organisation code.
  static Future<TenantRecord> beginSetup({
    required String organisationName,
    required String organisationId,
  }) async {
    final String name = organisationName.trim();
    final String orgId = organisationId.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(organisationName, 'organisationName', 'Organisation name is required.');
    }
    if (orgId.isEmpty) {
      throw ArgumentError.value(organisationId, 'organisationId', 'Organisation id is required.');
    }

    final TenantRecord? existing = await fetchByOrganisationId(orgId);
    if (existing != null) {
      if (existing.organisationName != name) {
        await _update(existing.tenantId, <String, dynamic>{'organisationName': name});
        return existing.copyWith(organisationName: name);
      }
      return existing;
    }

    final String tenantId = _col.doc().id;
    final TenantRecord record = TenantRecord(
      tenantId: tenantId,
      organisationCode: '',
      organisationName: name,
      firebaseProjectId: '',
      status: TenantStatus.setup,
      createdAt: DateTime.now().toUtc(),
      organisationId: orgId,
    );
    await _col.doc(tenantId).set(record.toMap());
    return record;
  }

  /// Binds an approved workspace. Rejects unknown project ids.
  static Future<TenantRecord> connectApprovedWorkspace({
    required String tenantId,
    required String firebaseProjectId,
  }) async {
    final TenantRecord current = await _require(tenantId);
    final String projectId = firebaseProjectId.trim();
    if (!ApprovedTenantFirebase.isApproved(projectId)) {
      throw StateError('That workspace is not approved for Hackz.');
    }
    final bool projectChanged = current.firebaseProjectId != projectId;
    await _update(tenantId, <String, dynamic>{
      'firebaseProjectId': projectId,
      if (projectChanged) 'firebaseValidated': false,
    });
    return current.copyWith(
      firebaseProjectId: projectId,
      firebaseValidated: projectChanged ? false : current.firebaseValidated,
    );
  }

  static Future<TenantRecord> markFirebaseValidated(String tenantId) {
    return _patch(tenantId, <String, dynamic>{'firebaseValidated': true}, (TenantRecord r) {
      return r.copyWith(firebaseValidated: true);
    });
  }

  static Future<TenantRecord> markHackzSetupComplete(String tenantId) {
    return _patch(tenantId, <String, dynamic>{'hackzSetupComplete': true}, (TenantRecord r) {
      return r.copyWith(hackzSetupComplete: true);
    });
  }

  static Future<TenantRecord> markInitialAdminConfigured(String tenantId) {
    return _patch(tenantId, <String, dynamic>{'initialAdminConfigured': true}, (TenantRecord r) {
      return r.copyWith(initialAdminConfigured: true);
    });
  }

  /// Assigns a unique `HKZ-XXXXXX` code and marks the tenant active.
  static Future<TenantRecord> activate(String tenantId) async {
    final TenantRecord current = await _require(tenantId);
    if (current.status == TenantStatus.active && OrganisationCode.isValid(current.organisationCode)) {
      return current;
    }
    if (!ApprovedTenantFirebase.isApproved(current.firebaseProjectId)) {
      throw StateError('Connect an approved workspace before activating.');
    }
    if (!current.firebaseValidated) {
      throw StateError('Finish workspace checks before activating.');
    }

    Object? lastCollision;
    for (int attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final String code = OrganisationCode.generate();
      final QuerySnapshot<Map<String, dynamic>> taken = await _col
          .where('organisationCode', isEqualTo: code)
          .limit(1)
          .get();
      if (taken.docs.isNotEmpty) {
        lastCollision = code;
        continue;
      }
      await _update(tenantId, <String, dynamic>{
        'organisationCode': code,
        'status': TenantStatus.active.wireValue,
      });
      return current.copyWith(organisationCode: code, status: TenantStatus.active);
    }
    throw StateError(
      'Unable to allocate a unique organisation code.${lastCollision == null ? '' : ' Last collision: $lastCollision'}',
    );
  }

  /// Registers an already-active tenant (legacy helper). Prefer [beginSetup] + [activate].
  static Future<TenantRecord> register({
    required String organisationName,
    String? firebaseProjectId,
    TenantStatus status = TenantStatus.active,
  }) async {
    final String name = organisationName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(organisationName, 'organisationName', 'Organisation name is required.');
    }

    final String projectId = (firebaseProjectId ?? ApprovedTenantFirebase.controlPlaneProjectId).trim();
    if (!ApprovedTenantFirebase.isApproved(projectId)) {
      throw StateError('Firebase project "$projectId" is not approved for Hackz tenancy.');
    }

    Object? lastCollision;
    for (int attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final String code = OrganisationCode.generate();
      final QuerySnapshot<Map<String, dynamic>> taken = await _col
          .where('organisationCode', isEqualTo: code)
          .limit(1)
          .get();
      if (taken.docs.isNotEmpty) {
        lastCollision = code;
        continue;
      }
      final String tenantId = _col.doc().id;
      final TenantRecord record = TenantRecord(
        tenantId: tenantId,
        organisationCode: code,
        organisationName: name,
        firebaseProjectId: projectId,
        status: status,
        createdAt: DateTime.now().toUtc(),
        firebaseValidated: status == TenantStatus.active,
        hackzSetupComplete: status == TenantStatus.active,
        initialAdminConfigured: status == TenantStatus.active,
      );
      await _col.doc(tenantId).set(record.toMap());
      return record;
    }
    throw StateError(
      'Unable to allocate a unique organisation code.${lastCollision == null ? '' : ' Last collision: $lastCollision'}',
    );
  }

  /// Resolves [rawCode] to exactly one **active** tenant with an approved project.
  static Future<TenantRecord?> resolveActive(String rawCode) async {
    try {
      final TenantRecord? record = await lookupByOrganisationCode(rawCode);
      if (record == null || record.status != TenantStatus.active) return null;
      if (!ApprovedTenantFirebase.isApproved(record.firebaseProjectId)) return null;
      return record;
    } on StateError {
      rethrow;
    }
  }

  /// Registry lookup by organisation code (any status). Throws if more than one match.
  static Future<TenantRecord?> lookupByOrganisationCode(String rawCode) async {
    final String? code = OrganisationCode.tryParse(rawCode);
    if (code == null) return null;

    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('organisationCode', isEqualTo: code)
        .get();

    final List<TenantRecord> matches = <TenantRecord>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final TenantRecord record = TenantRecord.fromMap(doc.data());
      if (OrganisationCode.tryParse(record.organisationCode) != code) continue;
      matches.add(record);
    }
    if (matches.isEmpty) return null;
    if (matches.length > 1) {
      throw StateError('Organisation code $code maps to ${matches.length} tenants.');
    }
    return matches.first;
  }

  static Future<TenantRecord?> fetchByOrganisationCode(String rawCode) async {
    final String? code = OrganisationCode.tryParse(rawCode);
    if (code == null) return null;
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('organisationCode', isEqualTo: code)
        .limit(2)
        .get();
    if (snap.docs.isNotEmpty) {
      return TenantRecord.fromMap(snap.docs.first.data());
    }
    final DocumentSnapshot<Map<String, dynamic>> legacy = await _col.doc(code).get();
    if (!legacy.exists || legacy.data() == null) return null;
    return TenantRecord.fromMap(legacy.data()!);
  }

  static Future<TenantRecord?> fetchByTenantId(String tenantId) async {
    final String id = tenantId.trim();
    if (id.isEmpty) return null;
    final DocumentReference<Map<String, dynamic>> ref = await _refForTenantId(id);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    if (!doc.exists || doc.data() == null) return null;
    return TenantRecord.fromMap(doc.data()!);
  }

  static Future<TenantRecord?> fetchByOrganisationId(String organisationId) async {
    final String id = organisationId.trim();
    if (id.isEmpty) return null;
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('organisationId', isEqualTo: id)
        .limit(2)
        .get();
    if (snap.docs.isEmpty) return null;
    final List<TenantRecord> open = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => TenantRecord.fromMap(doc.data()))
        .where((TenantRecord record) => record.status != TenantStatus.inactive)
        .toList(growable: false);
    if (open.isEmpty) return null;
    return open.first;
  }

  static Future<List<TenantRecord>> list() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col.get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      return TenantRecord.fromMap(doc.data());
    }).toList(growable: false);
  }

  /// Codes for organisation names that map to exactly one non-inactive tenant.
  static Map<String, String> uniqueCodesByOrganisationName(Iterable<TenantRecord> tenants) {
    final Map<String, int> counts = <String, int>{};
    final Map<String, String> codes = <String, String>{};
    for (final TenantRecord tenant in tenants) {
      if (tenant.status == TenantStatus.inactive) continue;
      if (!OrganisationCode.isValid(tenant.organisationCode)) continue;
      final String name = tenant.organisationName;
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
      codes[name] = tenant.organisationCode;
    }
    codes.removeWhere((String name, _) => (counts[name] ?? 0) != 1);
    return codes;
  }

  static Future<void> setStatus(String organisationCode, TenantStatus status) async {
    final TenantRecord? record = await fetchByOrganisationCode(organisationCode);
    if (record == null) {
      throw ArgumentError.value(organisationCode, 'organisationCode', 'Unknown organisation code.');
    }
    await _update(record.tenantId, <String, dynamic>{'status': status.wireValue});
  }

  static Future<void> setStatusForTenant(String tenantId, TenantStatus status) async {
    await _update(tenantId, <String, dynamic>{'status': status.wireValue});
  }

  /// Keeps registry [organisationName] in sync when a SysAdmin renames an org.
  static Future<void> syncOrganisationName({
    required String previousName,
    required String nextName,
    String? organisationId,
  }) async {
    final String next = nextName.trim();
    if (next.isEmpty) return;
    TenantRecord? tenant;
    final String orgId = (organisationId ?? '').trim();
    if (orgId.isNotEmpty) {
      tenant = await fetchByOrganisationId(orgId);
    }
    tenant ??= await _uniqueByOrganisationName(previousName);
    if (tenant == null) return;
    if (tenant.organisationName == next) return;
    await _update(tenant.tenantId, <String, dynamic>{'organisationName': next});
  }

  static Future<void> inactivateByOrganisationName(String organisationName) async {
    final TenantRecord? tenant = await _uniqueByOrganisationName(organisationName);
    if (tenant == null) return;
    await setStatusForTenant(tenant.tenantId, TenantStatus.inactive);
  }

  static Future<void> inactivateByOrganisationId(String organisationId) async {
    final TenantRecord? tenant = await fetchByOrganisationId(organisationId);
    if (tenant == null) {
      return;
    }
    await setStatusForTenant(tenant.tenantId, TenantStatus.inactive);
  }

  static Future<TenantRecord> _patch(
    String tenantId,
    Map<String, dynamic> fields,
    TenantRecord Function(TenantRecord current) apply,
  ) async {
    final TenantRecord current = await _require(tenantId);
    await _update(tenantId, fields);
    return apply(current);
  }

  static Future<TenantRecord> _require(String tenantId) async {
    final TenantRecord? record = await fetchByTenantId(tenantId);
    if (record == null) {
      throw StateError('That organisation is no longer in the registry.');
    }
    return record;
  }

  static Future<void> _update(String tenantId, Map<String, dynamic> fields) async {
    final DocumentReference<Map<String, dynamic>> ref = await _refForTenantId(tenantId);
    await ref.update(fields);
  }

  static Future<DocumentReference<Map<String, dynamic>>> _refForTenantId(String tenantId) async {
    final String id = tenantId.trim();
    final DocumentSnapshot<Map<String, dynamic>> direct = await _col.doc(id).get();
    if (direct.exists) return direct.reference;
    final QuerySnapshot<Map<String, dynamic>> byField = await _col.where('tenantId', isEqualTo: id).limit(1).get();
    if (byField.docs.isNotEmpty) return byField.docs.first.reference;
    return _col.doc(id);
  }

  static Future<TenantRecord?> _uniqueByOrganisationName(String organisationName) async {
    final String name = organisationName.trim();
    if (name.isEmpty) return null;
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('organisationName', isEqualTo: name)
        .get();
    final List<TenantRecord> matches = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => TenantRecord.fromMap(doc.data()))
        .where((TenantRecord record) => record.status != TenantStatus.inactive)
        .toList(growable: false);
    if (matches.length != 1) return null;
    return matches.first;
  }
}
