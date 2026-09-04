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

  /// Registers a tenant against an approved Firebase project.
  ///
  /// [firebaseProjectId] defaults to the Control Plane project. Arbitrary
  /// project ids and Firebase options from callers are rejected.
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
      final String tenantId = _col.doc().id;
      final TenantRecord record = TenantRecord(
        tenantId: tenantId,
        organisationCode: code,
        organisationName: name,
        firebaseProjectId: projectId,
        status: status,
        createdAt: DateTime.now().toUtc(),
      );
      final DocumentReference<Map<String, dynamic>> ref = _col.doc(code);
      try {
        await _db.runTransaction((Transaction txn) async {
          final DocumentSnapshot<Map<String, dynamic>> existing = await txn.get(ref);
          if (existing.exists) {
            throw const _OrganisationCodeTaken();
          }
          txn.set(ref, record.toMap());
        });
        return record;
      } on _OrganisationCodeTaken {
        lastCollision = code;
      }
    }
    throw StateError(
      'Unable to allocate a unique organisation code.${lastCollision == null ? '' : ' Last collision: $lastCollision'}',
    );
  }

  /// Resolves [rawCode] to exactly one **active** tenant with an approved project.
  ///
  /// Returns `null` when the code is invalid, unknown, inactive, still in
  /// setup, or pointed at an unapproved Firebase project. Throws if more than
  /// one active tenant shares the code (data-integrity failure).
  static Future<TenantRecord?> resolveActive(String rawCode) async {
    final String? code = OrganisationCode.tryParse(rawCode);
    if (code == null) return null;

    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('organisationCode', isEqualTo: code)
        .get();

    final List<TenantRecord> active = <TenantRecord>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final TenantRecord record = TenantRecord.fromMap(doc.data());
      if (record.status != TenantStatus.active) continue;
      if (!ApprovedTenantFirebase.isApproved(record.firebaseProjectId)) continue;
      if (OrganisationCode.tryParse(record.organisationCode) != code) continue;
      active.add(record);
    }

    if (active.isEmpty) return null;
    if (active.length > 1) {
      throw StateError('Organisation code $code maps to ${active.length} active tenants.');
    }
    return active.first;
  }

  static Future<TenantRecord?> fetchByOrganisationCode(String rawCode) async {
    final String? code = OrganisationCode.tryParse(rawCode);
    if (code == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(code).get();
    if (!doc.exists || doc.data() == null) return null;
    return TenantRecord.fromMap(doc.data()!);
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
      final String name = tenant.organisationName;
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
      codes[name] = tenant.organisationCode;
    }
    codes.removeWhere((String name, _) => (counts[name] ?? 0) != 1);
    return codes;
  }

  static Future<void> setStatus(String organisationCode, TenantStatus status) async {
    final String? code = OrganisationCode.tryParse(organisationCode);
    if (code == null) {
      throw ArgumentError.value(organisationCode, 'organisationCode', 'Invalid organisation code.');
    }
    await _col.doc(code).update(<String, dynamic>{'status': status.wireValue});
  }

  /// Keeps registry [organisationName] in sync when a SysAdmin renames an org.
  /// No-op when the previous name is missing or not unique in the registry.
  static Future<void> syncOrganisationName({
    required String previousName,
    required String nextName,
  }) async {
    final String previous = previousName.trim();
    final String next = nextName.trim();
    if (previous.isEmpty || next.isEmpty || previous == next) return;
    final TenantRecord? tenant = await _uniqueByOrganisationName(previous);
    if (tenant == null) return;
    await _col.doc(tenant.organisationCode).update(<String, dynamic>{
      'organisationName': next,
    });
  }

  /// Marks the unique matching tenant inactive after an organisation is deleted.
  static Future<void> inactivateByOrganisationName(String organisationName) async {
    final TenantRecord? tenant = await _uniqueByOrganisationName(organisationName);
    if (tenant == null) return;
    await setStatus(tenant.organisationCode, TenantStatus.inactive);
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

class _OrganisationCodeTaken implements Exception {
  const _OrganisationCodeTaken();
}
