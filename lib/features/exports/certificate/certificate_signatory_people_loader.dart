import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';

/// Eligible people for certificate signatory prefilling (not hard-coded users).
abstract final class CertificateSignatoryPeopleLoader {
  CertificateSignatoryPeopleLoader._();

  static Future<List<UserModel>> load({
    required String orgId,
    required String departmentCode,
    Iterable<String> eventCoordinatorIds = const <String>[],
  }) async {
    final String org = orgId.trim();
    if (org.isEmpty) return const <UserModel>[];

    final String normalizedDept = departmentCode.trim().toUpperCase();
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries =
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
      HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: org)
          .where('role', isEqualTo: UserRole.collegeAdmin.code)
          .get(),
      HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: org)
          .where('role', isEqualTo: UserRole.orgAdmin.code)
          .get(),
      HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: org)
          .where('role', isEqualTo: UserRole.departmentAdmin.code)
          .get(),
      HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: org)
          .where('role', isEqualTo: UserRole.coordinator.code)
          .get(),
    ];

    final List<QuerySnapshot<Map<String, dynamic>>> results =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(queries);
    final Map<String, UserModel> byId = <String, UserModel>{};

    for (final QuerySnapshot<Map<String, dynamic>> snap in results) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
        if (!_includeUser(user, normalizedDept)) continue;
        byId[user.userId.trim()] = user;
      }
    }

    final List<String> coordinatorIds = <String>{
      for (final String raw in eventCoordinatorIds) raw.trim(),
    }.where((String id) => id.isNotEmpty).toList(growable: false);
    if (coordinatorIds.isNotEmpty) {
      final List<UserModel> eventCoordinators = await _fetchByIds(coordinatorIds);
      for (final UserModel user in eventCoordinators) {
        byId[user.userId.trim()] = user;
      }
    }

    final List<UserModel> users = byId.values.toList()
      ..sort((UserModel a, UserModel b) => userDisplayName(a).compareTo(userDisplayName(b)));
    return users;
  }

  static bool _includeUser(UserModel user, String normalizedDept) {
    final UserRole role = UserRole.fromCode(user.role);
    if (role == UserRole.collegeAdmin || role == UserRole.orgAdmin) return true;
    if (normalizedDept.isEmpty) return true;
    return user.departmentCode.trim().toUpperCase() == normalizedDept;
  }

  static Future<List<UserModel>> _fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const <UserModel>[];
    final List<UserModel> out = <UserModel>[];
    for (final List<String> chunk in _chunks(ids, 10)) {
      final QuerySnapshot<Map<String, dynamic>> snap = await HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzUsers)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
        out.add(user);
      }
    }
    return out;
  }

  static Iterable<List<String>> _chunks(List<String> items, int size) sync* {
    for (int i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }

  /// Default certificate designation from profile (does not write back to Firestore).
  static String defaultDesignation(UserModel user) {
    final UserRole role = UserRole.fromCode(user.role);
    final String office = switch (role) {
      UserRole.collegeAdmin => user.profile?.collegeAdminProfile?.officeDesignation ?? '',
      UserRole.departmentAdmin => user.profile?.departmentAdminProfile?.officeDesignation ?? '',
      _ => user.profile?.professionalProfile?.designation ?? '',
    };
    if (office.trim().isNotEmpty) return office.trim();
    return switch (role) {
      UserRole.collegeAdmin => 'College Admin',
      UserRole.orgAdmin => 'Organisation Admin',
      UserRole.departmentAdmin => 'Department Admin',
      UserRole.coordinator => 'Coordinator',
      _ => '',
    };
  }
}
