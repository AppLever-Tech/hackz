import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../models/domain_model.dart';

/// CRUD and queries for [DomainModel] in `hkzDomains`.
abstract final class DomainService {
  DomainService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(FirestoreUtils.hkzDomains);

  static Future<List<DomainModel>> listByOrg({
    required String orgId,
    String? departmentId,
    bool activeOnly = false,
  }) async {
    final String org = orgId.trim();
    if (org.isEmpty) return const <DomainModel>[];

    Query<Map<String, dynamic>> query = _collection.where('orgId', isEqualTo: org);
    final String deptId = (departmentId ?? '').trim();
    if (deptId.isNotEmpty) {
      query = query.where('departmentId', isEqualTo: deptId);
    }

    final QuerySnapshot<Map<String, dynamic>> snap = await query.get();
    List<DomainModel> domains = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => DomainModel.fromMap(d.id, d.data()))
        .toList(growable: true);

    if (activeOnly) {
      domains = domains.where((DomainModel d) => d.isActive).toList(growable: true);
    }

    domains.sort((DomainModel a, DomainModel b) {
      final int byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return a.code.compareTo(b.code);
    });
    return domains;
  }

  static Future<DomainModel?> fetchById(String domainId) async {
    final String id = domainId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> snap = await _collection.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return DomainModel.fromMap(snap.id, snap.data()!);
  }

  static Future<Map<String, DomainModel>> fetchByIds(Iterable<String> domainIds) async {
    final Set<String> ids = domainIds.map((String e) => e.trim()).where((String e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return const <String, DomainModel>{};

    final Map<String, DomainModel> result = <String, DomainModel>{};
    for (final String id in ids) {
      final DomainModel? domain = await fetchById(id);
      if (domain != null) result[id] = domain;
    }
    return result;
  }

  /// Resolve domain by code within a department (org-scoped).
  static Future<DomainModel?> findByCode({
    required String orgId,
    required String departmentId,
    required String code,
  }) async {
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final List<DomainModel> domains = await listByOrg(orgId: orgId, departmentId: departmentId);
    for (final DomainModel d in domains) {
      if (d.code == normalized) return d;
    }
    return null;
  }

  static Future<DomainModel> create({
    required String orgId,
    required String departmentId,
    required String code,
    required String name,
    String description = '',
    String icon = '',
    bool isActive = true,
  }) async {
    final String normalizedCode = code.trim().toUpperCase();
    final String normalizedName = name.trim();
    if (orgId.trim().isEmpty) throw StateError('orgId is required');
    if (departmentId.trim().isEmpty) throw StateError('departmentId is required');
    if (normalizedCode.isEmpty) throw StateError('Domain code is required');
    if (normalizedName.isEmpty) throw StateError('Domain name is required');

    final DomainModel? existing = await findByCode(
      orgId: orgId,
      departmentId: departmentId,
      code: normalizedCode,
    );
    if (existing != null) {
      throw StateError('Domain code "$normalizedCode" already exists in this department.');
    }

    final DocumentReference<Map<String, dynamic>> ref = _collection.doc();
    final DomainModel domain = DomainModel(
      domainId: ref.id,
      departmentId: departmentId.trim(),
      code: normalizedCode,
      name: normalizedName,
      description: description.trim(),
      icon: icon.trim(),
      isActive: isActive,
      orgId: orgId.trim(),
    );
    await ref.set(domain.toMap());
    return domain;
  }

  static Future<void> update(DomainModel domain) async {
    final String id = domain.domainId.trim();
    if (id.isEmpty) throw StateError('domainId is required');
    await _collection.doc(id).set(domain.toMap(), SetOptions(merge: true));
  }

  static Future<void> setActive({required String domainId, required bool isActive}) async {
    final String id = domainId.trim();
    if (id.isEmpty) return;
    await _collection.doc(id).update(<String, dynamic>{'isActive': isActive});
  }
}
