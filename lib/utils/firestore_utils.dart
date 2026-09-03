import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/organization/models/department_model.dart';
import '../features/idea/services/idea_department_helpers.dart';
import 'package:hackz/features/idea/models/enums/idea_status.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../features/organization/models/organization_model.dart';
import '../features/organization/models/enums/organization_type.dart';
import '../features/user/models/enums/user_role.dart';
import '../features/user/models/enums/user_status.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../features/problems/models/problem_model.dart';
import '../features/team/models/team_model.dart';
import '../features/user/models/user_model.dart';
import 'common_helpers.dart';

class FirestoreUtils {
  FirestoreUtils._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String hkzUsers = 'hkzUsers';
  static const String hkzOrganizations = 'hkzOrganizations';
  static const String hkzSysAdminWhitelist = 'hkzSysAdminWhitelist';
  static const String hkzInviteCodes = 'hkzInviteCodes';
  static const String hkzCounters = 'hkzCounters';
  static const String hkzIdeas = 'hkzIdeas';
  static const String hkzScores = 'hkzScores';
  static const String hkzDepartments = 'hkzDepartments';
  static const String hkzProblems = 'hkzProblems';
  static const String hkzPayments = 'hkzPayments';
  /// Links Firebase Auth UID → `hkzUsers` document id (for rules + coordinator checks).
  static const String hkzUserAuthMirror = 'hkzUserAuthMirror';
  static const String hkzTeams = 'hkzTeams';
  static const String hkzAttachments = 'hkzAttachments';
  /// Generic workflow / approval requests (team changes, future payment / idea / extension approvals).
  static const String hkzRequests = 'hkzRequests';
  /// Problem-level evaluation assignment grouping.
  static const String hkzEvaluationGroups = 'hkzEvaluationGroups';
  /// Idea-to-judge evaluation assignments (supports many judges per idea).
  static const String hkzEvaluationAssignments = 'hkzEvaluationAssignments';
  static const String hkzIdeathons = 'hkzIdeathons';
  /// Idea ↔ Ideathon membership (idea already paid before create).
  static const String hkzIdeathonParticipations = 'hkzIdeathonParticipations';
  static const String hkzAppMetadata = 'hkzAppMetadata';
  static const String hkzDomains = 'hkzDomains';
  static const String hkzFeedback = 'hkzFeedback';

  static String _resolveDepartmentCode(String raw) {
    return DepartmentModel.resolveCode(raw);
  }

  static bool _matchesDepartmentCode(Map<String, dynamic> data, String departmentCode) {
    final target = departmentCode.trim().toUpperCase();
    if (target.isEmpty) return false;
    final code = ((data['departmentCode'] as String?) ?? '').trim().toUpperCase();
    return code == target;
  }

  static Future<UserModel?> fetchUser(String userId) async {
    final doc = await _db.collection(hkzUsers).doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!).copyWith(userId: doc.id);
  }

  static Future<UserModel?> fetchUserByPhone(String phone) async {
    final normalizedPhone = normalizePhoneE164(phone);

    final hkzQuery = await _db
        .collection(hkzUsers)
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (hkzQuery.docs.isEmpty) return null;
    final doc = hkzQuery.docs.first;
    return UserModel.fromMap(doc.data()).copyWith(userId: doc.id);
  }

  static Future<String> createUser(UserModel user) async {
    final existing = await fetchUserByPhone(user.phone);
    if (existing != null) {
      throw StateError('User already exists for this phone.');
    }

    final String userId = user.userId.isEmpty
        ? _db.collection(hkzUsers).doc().id
        : user.userId;
    await _db.collection(hkzUsers).doc(userId).set(
          user.copyWith(userId: userId).toMap(),
        );
    return userId;
  }

  /// First-time whitelisted sysadmin: writes exactly one `hkzUsers/{firebaseAuthUid}` row.
  /// Using the Auth UID as document id matches `fetchUser(uid)` in AuthGate and avoids
  /// duplicate profiles when the resolver runs more than once before the first write commits.
  static Future<void> ensureWhitelistedSysAdminProfile({
    required String firebaseAuthUid,
    required UserModel profile,
  }) async {
    final uid = firebaseAuthUid.trim();
    if (uid.isEmpty) return;

    final normalizedPhone = normalizePhoneE164(profile.phone);
    if (normalizedPhone.isEmpty) return;

    if ((await fetchUserByPhone(normalizedPhone)) != null) return;

    await _db.runTransaction((Transaction txn) async {
      final userRef = _db.collection(hkzUsers).doc(uid);
      final byUid = await txn.get(userRef);
      if (byUid.exists) return;

      txn.set(userRef, profile.copyWith(userId: uid).toMap());
    });
  }

  static Future<void> updateUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _db.collection(hkzUsers).doc(userId).update(updates);
  }

  static Future<Map<String, dynamic>?> fetchInviteCode(String code) async {
    final raw = code.trim();
    if (raw.isEmpty) return null;

    Future<Map<String, dynamic>?> runLookup(String value) async {
      final query = await _db
          .collection(hkzInviteCodes)
          .where('code', isEqualTo: value)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first.data();
    }

    final direct = await runLookup(raw);
    if (direct != null) return direct;

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6) {
      final formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
      final formattedHit = await runLookup(formatted);
      if (formattedHit != null) return formattedHit;

      if (digits != raw) {
        final digitHit = await runLookup(digits);
        if (digitHit != null) return digitHit;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchWhitelistEntry(String phone) async {
    final query = await _db
        .collection(hkzSysAdminWhitelist)
        .where('phone', isEqualTo: phone)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  static Stream<List<UserModel>> watchPendingUsers({
    required String orgId,
    required String departmentCode,
  }) {
    final normalizedDept = DepartmentModel.resolveCode(departmentCode);
    return _db
        .collection(hkzUsers)
        .where('status', isEqualTo: UserStatus.pendingApproval.value)
        .where('orgId', isEqualTo: orgId)
        .where('departmentCode', isEqualTo: normalizedDept)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()).copyWith(userId: doc.id))
              .toList(growable: false),
        );
  }

  static Stream<List<UserModel>> watchUsersByOrgAndRole({
    required String orgId,
    required String roleCode,
  }) {
    return _db
        .collection(hkzUsers)
        .where('orgId', isEqualTo: orgId)
        .where('role', isEqualTo: roleCode)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromMap(doc.data()).copyWith(userId: doc.id))
                  .toList(growable: false),
        );
  }

  static Future<Map<String, int>> fetchDashboardStats(UserModel user) async {
    Query<Map<String, dynamic>> query = _db.collection(hkzUsers);

    // Role-specific data scope: sysadmin can see all, others are org scoped.
    if (user.role != 'SADM' && user.orgId.isNotEmpty) {
      query = query.where('orgId', isEqualTo: user.orgId);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    int activeCount = 0;
    int pendingCount = 0;
    for (final doc in docs) {
      final status = UserStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      if (status == UserStatus.active) {
        activeCount++;
      } else if (status == UserStatus.pendingApproval) {
        pendingCount++;
      }
    }

    return <String, int>{
      'total': docs.length,
      'active': activeCount,
      'pending': pendingCount,
    };
  }

  static Future<int> getTotalOrganizations() async {
    final snapshot = await _db.collection(hkzOrganizations).get();
    return snapshot.docs.length;
  }

  static Future<int> getTotalUsers() async {
    final snapshot = await _db.collection(hkzUsers).get();
    return snapshot.docs.length;
  }

  static Future<int> getActiveUsers() async {
    final snapshot = await _db.collection(hkzUsers).where('status', isEqualTo: UserStatus.active.value).get();
    return snapshot.docs.length;
  }

  static Future<int> getIdeasCount() async {
    final snapshot = await _db.collection(hkzIdeas).get();
    return snapshot.docs.length;
  }

  static Future<int> getProblemsCount() async {
    final snapshot = await _db.collection(hkzProblems).get();
    return snapshot.docs.length;
  }

  static Future<List<Map<String, dynamic>>> getOrgStats() async {
    final organizations = await getOrganizations();
    final usersSnapshot = await _db.collection(hkzUsers).get();
    final ideasSnapshot = await _db.collection(hkzIdeas).get();

    final Map<String, int> ideaCountByOrg = <String, int>{};
    for (final doc in ideasSnapshot.docs) {
      final orgId = (doc.data()['orgId'] as String?)?.trim() ?? '';
      if (orgId.isEmpty) continue;
      ideaCountByOrg[orgId] = (ideaCountByOrg[orgId] ?? 0) + 1;
    }

    final Map<String, Map<String, dynamic>> orgStats = <String, Map<String, dynamic>>{
      for (final org in organizations)
        org.id: <String, dynamic>{
          'orgId': org.id,
          'name': org.name,
          'type': OrganizationType.displayLabelOf(org.type),
          'totalUsers': 0,
          'activeUsers': 0,
          'pendingUsers': 0,
          'totalIdeas': 0,
        },
    };
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final String orgId = (data['orgId'] as String?)?.trim() ?? '';
      if (orgId.isEmpty) continue;

      final String orgName = (data['orgName'] as String?)?.trim().isNotEmpty == true
          ? (data['orgName'] as String).trim()
          : orgId;
      final OrganizationType? type = OrganizationType.fromFirestoreValue(data['orgType']);
      final status = UserStatus.fromRaw((data['status'] as String?) ?? '');

      final current = orgStats.putIfAbsent(
        orgId,
        () => <String, dynamic>{
          'orgId': orgId,
          'name': orgName,
          'type': OrganizationType.displayLabelOf(type),
          'totalUsers': 0,
          'activeUsers': 0,
          'pendingUsers': 0,
          'totalIdeas': 0,
        },
      );

      current['totalUsers'] = (current['totalUsers'] as int) + 1;
      if (status == UserStatus.active) {
        current['activeUsers'] = (current['activeUsers'] as int) + 1;
      } else if (status == UserStatus.pendingApproval) {
        current['pendingUsers'] = (current['pendingUsers'] as int) + 1;
      }
    }

    for (final entry in orgStats.entries) {
      entry.value['totalIdeas'] = ideaCountByOrg[entry.key] ?? 0;
    }

    final list = orgStats.values.toList(growable: false);
    list.sort(
      (a, b) => ((b['totalUsers'] as int?) ?? 0).compareTo((a['totalUsers'] as int?) ?? 0),
    );
    return list;
  }

  static Future<List<OrganizationModel>> getOrganizations() async {
    final snapshot = await _db.collection(hkzOrganizations).get();
    final items = snapshot.docs
        .map((doc) => OrganizationModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  static Future<OrganizationModel?> fetchOrganization(String orgId) async {
    final id = orgId.trim();
    if (id.isEmpty) return null;
    final doc = await _db.collection(hkzOrganizations).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrganizationModel.fromMap(doc.id, doc.data()!);
  }

  /// Returns the resolved organization id (newly generated for inserts or
  /// the existing id for edits). Callers can chain post-create work such as
  /// seeding per-org settings.
  static Future<String> upsertOrganization(OrganizationModel org) async {
    final docRef = org.id.isEmpty
        ? _db.collection(hkzOrganizations).doc()
        : _db.collection(hkzOrganizations).doc(org.id);
    final payload = org.copyWith(id: docRef.id).toMap();
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  static Future<void> deleteOrganization(String orgId) async {
    final normalizedOrgId = orgId.trim();
    if (normalizedOrgId.isEmpty) return;
    final orgRef = _db.collection(hkzOrganizations).doc(normalizedOrgId);

    // Firestore does not cascade subcollection deletes when deleting a parent doc.
    // Clean known org-scoped subcollections first.
    await _deleteSubcollectionDocs(orgRef.collection('settings'));

    await orgRef.delete();
  }

  static Future<void> _deleteSubcollectionDocs(
    CollectionReference<Map<String, dynamic>> collectionRef,
  ) async {
    final snapshot = await collectionRef.get();
    if (snapshot.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<void> deleteUser(String userId) async {
    await _db.collection(hkzUsers).doc(userId).delete();
  }

  static Future<List<Map<String, dynamic>>> getDepartmentsByCollege(String orgId) async {
    final usersSnapshot = await _db.collection(hkzUsers).where('orgId', isEqualTo: orgId).get();
    final Query<Map<String, dynamic>> departmentsQuery =
        _db.collection(hkzDepartments).where('orgId', isEqualTo: orgId);
    QuerySnapshot<Map<String, dynamic>> departmentsSnapshot;
    try {
      departmentsSnapshot = await departmentsQuery.get(const GetOptions(source: Source.server));
    } catch (_) {
      departmentsSnapshot = await departmentsQuery.get();
    }

    final Map<String, Map<String, dynamic>> byCode = <String, Map<String, dynamic>>{};
    final Map<String, Map<String, dynamic>> byName = <String, Map<String, dynamic>>{};
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> dep in departmentsSnapshot.docs) {
      final Map<String, dynamic> data = dep.data();
      final String name = (data['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      final String code = (data['code'] as String?)?.trim().toUpperCase() ?? '';
      final Map<String, dynamic> row = <String, dynamic>{
        'id': dep.id,
        'name': name,
        'code': code,
        'adminUserId': (data['adminUserId'] as String?)?.trim() ?? '',
        'departmentAdmin': '-',
        'totalUsers': 0,
        'facultyCount': 0,
        'teamMemberCount': 0,
        'judgeCount': 0,
        'coordinatorCount': 0,
      };
      rows.add(row);
      if (code.isNotEmpty) byCode[code] = row;
      byName[name.toLowerCase()] = row;
    }

    final Map<String, UserModel> usersById = <String, UserModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> u in usersSnapshot.docs) {
      final Map<String, dynamic> data = u.data();
      final String department = (data['department'] as String?)?.trim() ?? '';
      final String departmentCode = ((data['departmentCode'] as String?) ?? '').trim().toUpperCase();
      final String role = (data['role'] as String?) ?? '';
      final String firstName = (data['firstName'] as String?)?.trim() ?? '';
      final String lastName = (data['lastName'] as String?)?.trim() ?? '';
      final String fullName = '$firstName $lastName'.trim();

      Map<String, dynamic>? current;
      if (departmentCode.isNotEmpty) current = byCode[departmentCode];
      if (current == null) {
        final String departmentName =
            (DepartmentModel.byCode(departmentCode)?.name ?? department).trim();
        if (departmentName.isNotEmpty) current = byName[departmentName.toLowerCase()];
      }
      if (current != null) {
        current['totalUsers'] = (current['totalUsers'] as int) + 1;
        if (role == 'DADM' && fullName.isNotEmpty) {
          current['departmentAdmin'] = fullName;
        }
        if (role == UserRole.teamMember.code) {
          current['teamMemberCount'] = (current['teamMemberCount'] as int) + 1;
        } else if (role == UserRole.judge.code) {
          current['judgeCount'] = (current['judgeCount'] as int? ?? 0) + 1;
        } else if (role == UserRole.coordinator.code) {
          current['coordinatorCount'] = (current['coordinatorCount'] as int? ?? 0) + 1;
        }
      }

      final UserModel userModel = UserModel.fromMap(data);
      usersById[userModel.userId.isNotEmpty ? userModel.userId : u.id] = userModel.copyWith(
        userId: userModel.userId.isNotEmpty ? userModel.userId : u.id,
      );
    }

    for (final Map<String, dynamic> row in rows) {
      final String adminUserId = (row['adminUserId'] as String?)?.trim() ?? '';
      if (adminUserId.isEmpty) continue;
      final UserModel? admin = usersById[adminUserId];
      if (admin == null) continue;
      final String fullName = '${admin.firstName} ${admin.lastName}'.trim();
      row['departmentAdmin'] = fullName.isEmpty ? '-' : fullName;
      row['adminUser'] = admin;
    }

    rows.sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['name'] as String).compareTo(b['name'] as String),
    );
    return rows;
  }

  /// Idea totals keyed by department code — used by analytics charts, not manage-college.
  static Future<Map<String, int>> getIdeaCountsByDepartmentCode(String orgId) async {
    final ideasSnapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();
    final Map<String, int> counts = <String, int>{};
    for (final doc in ideasSnapshot.docs) {
      final String departmentCode = IdeaDepartmentHelpers.teamDeptFromMap(doc.data());
      if (departmentCode.isEmpty) continue;
      counts[departmentCode] = (counts[departmentCode] ?? 0) + 1;
    }
    return counts;
  }

  static Future<Map<String, dynamic>> getCollegeStats(String orgId) async {
    final usersSnapshot = await _db.collection(hkzUsers).where('orgId', isEqualTo: orgId).get();
    final ideasSnapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();
    final problemsSnapshot = await _db.collection(hkzProblems).where('orgId', isEqualTo: orgId).get();
    final departmentsSnapshot = await _db
        .collection(hkzDepartments)
        .where('orgId', isEqualTo: orgId)
        .get();

    final totalUsers = usersSnapshot.docs.length;
    final activeUsers = usersSnapshot.docs
        .where((d) => UserStatus.fromRaw((d.data()['status'] as String?) ?? '') == UserStatus.active)
        .length;
    final pendingUsers = usersSnapshot.docs
        .where((d) => UserStatus.fromRaw((d.data()['status'] as String?) ?? '') == UserStatus.pendingApproval)
        .length;

    return <String, dynamic>{
      'totalDepartments': departmentsSnapshot.docs.length,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'pendingUsers': pendingUsers,
      'totalProblems': problemsSnapshot.docs.length,
      'totalIdeas': ideasSnapshot.docs.length,
    };
  }

  static Future<List<Map<String, dynamic>>> getCollegeIdeaActivityTrend(String orgId) async {
    final ideasSnapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 25));
    final buckets = List<DateTime>.generate(6, (int i) => start.add(Duration(days: i * 5)));
    final counts = List<int>.filled(buckets.length, 0);

    for (final doc in ideasSnapshot.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null || createdAt.isBefore(start)) continue;
      for (int i = 0; i < buckets.length; i++) {
        final from = buckets[i];
        final to = i == buckets.length - 1 ? now.add(const Duration(days: 1)) : buckets[i + 1];
        if (!createdAt.isBefore(from) && createdAt.isBefore(to)) {
          counts[i]++;
          break;
        }
      }
    }

    return List<Map<String, dynamic>>.generate(
      buckets.length,
      (int i) => <String, dynamic>{
        'label': '${buckets[i].day}/${buckets[i].month}',
        'count': counts[i],
      },
      growable: false,
    );
  }

  static Future<List<Map<String, dynamic>>> getIdeasByCollege(String orgId) async {
    final ideasSnapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();
    final Map<String, Map<String, dynamic>> grouped = <String, Map<String, dynamic>>{};
    int evaluatedIdeas = 0;

    for (final doc in ideasSnapshot.docs) {
      final data = doc.data();
      final problem = (data['problemTitle'] as String?)?.trim().isNotEmpty == true
          ? (data['problemTitle'] as String).trim()
          : ((data['problemId'] as String?)?.trim().isNotEmpty == true
              ? (data['problemId'] as String).trim()
              : 'Unmapped Problem');
      final IdeaStatus status = IdeaStatus.fromRaw((data['status'] as String?) ?? IdeaStatus.submitted.value);
      final bucket = grouped.putIfAbsent(
        problem,
        () => <String, dynamic>{
          'problem': problem,
          'totalIdeas': 0,
          'submitted': 0,
          'underReview': 0,
          'evaluated': 0,
        },
      );
      bucket['totalIdeas'] = (bucket['totalIdeas'] as int) + 1;
      if (status == IdeaStatus.submitted) {
        bucket['submitted'] = (bucket['submitted'] as int) + 1;
        // Eval aggregates still live on the idea; count scored submissions as evaluated for charts.
        if (((data['totalEvaluators'] as num?)?.toInt() ?? 0) > 0) {
          bucket['evaluated'] = (bucket['evaluated'] as int) + 1;
          evaluatedIdeas++;
        }
      }
    }

    final items = grouped.values.toList(growable: false);
    items.sort((a, b) => (b['totalIdeas'] as int).compareTo(a['totalIdeas'] as int));
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'totalIdeas': ideasSnapshot.docs.length,
        'evaluatedIdeas': evaluatedIdeas,
      },
      ...items,
    ];
  }

  static Future<String> addDepartment({
    required String orgId,
    required String name,
    required String code,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref =
        await _db.collection(hkzDepartments).add(<String, dynamic>{
      'orgId': orgId,
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'adminUserId': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateDepartment({
    required String departmentId,
    required String name,
    required String code,
  }) async {
    await _db.collection(hkzDepartments).doc(departmentId).set(<String, dynamic>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> setDepartmentAdmin({
    required String departmentId,
    required String adminUserId,
  }) async {
    await _db.collection(hkzDepartments).doc(departmentId).set(<String, dynamic>{
      'adminUserId': adminUserId.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> clearDepartmentAdmin({
    required String departmentId,
  }) async {
    await _db.collection(hkzDepartments).doc(departmentId).set(<String, dynamic>{
      'adminUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteDepartment({required String departmentId}) async {
    final String id = departmentId.trim();
    if (id.isEmpty) {
      throw StateError('Department record id is required to delete a department.');
    }
    await _db.collection(hkzDepartments).doc(id).delete();
  }

  static Future<void> addProblemStatement({
    required String orgId,
    required String title,
    required String description,
    required String department,
    required String tags,
  }) async {
    final departmentCode = _resolveDepartmentCode(department);
    await _db.collection(hkzProblems).add(<String, dynamic>{
      'orgId': orgId,
      'title': title.trim(),
      'description': description.trim(),
      'department': departmentCode,
      'departmentCode': departmentCode,
      'tags': tags.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> createProblem(ProblemModel problem) async {
    return createProblemWithId(problem: problem);
  }

  static Future<String> createProblemWithId({
    required ProblemModel problem,
    String? problemId,
  }) async {
    final doc = _db.collection(hkzProblems).doc();
    final targetId = (problemId ?? '').trim().isEmpty ? doc.id : problemId!.trim();
    final ref = _db.collection(hkzProblems).doc(targetId);
    final payload = problem.toMap()
      ..['problemId'] = targetId
      ..['updatedAt'] = problem.updatedAt == null ? null : Timestamp.fromDate(problem.updatedAt!);
    await ref.set(payload, SetOptions(merge: true));
    return targetId;
  }

  static Future<void> updateProblem(String problemId, Map<String, dynamic> updates) async {
    final payload = <String, dynamic>{
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _db.collection(hkzProblems).doc(problemId).set(payload, SetOptions(merge: true));
  }

  static Future<void> deleteProblem(String problemId) async {
    await _db.collection(hkzProblems).doc(problemId).delete();
  }

  static Future<String> createTeam(TeamModel team) async {
    final doc = _db.collection(hkzTeams).doc();
    await doc.set(
      team.copyWith(teamId: doc.id).toMap(),
      SetOptions(merge: true),
    );
    return doc.id;
  }

  static Future<void> updateTeam(String teamId, Map<String, dynamic> updates) async {
    await _db.collection(hkzTeams).doc(teamId).set(
      updates,
      SetOptions(merge: true),
    );
  }

  static Future<void> deleteTeam(String teamId) async {
    await _db.collection(hkzTeams).doc(teamId).delete();
  }

  static Future<Map<String, String>> getTeamNamesByOrg(String orgId) async {
    final snapshot = await _db.collection(hkzTeams).where('orgId', isEqualTo: orgId).get();
    final mapped = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = ((data['teamId'] as String?) ?? '').trim().isNotEmpty
          ? ((data['teamId'] as String?) ?? '').trim()
          : doc.id;
      final name = ((data['teamName'] as String?) ?? '').trim();
      mapped[id] = name.isEmpty ? id : name;
    }
    return mapped;
  }

  static Future<List<TeamModel>> getTeamsLedBy(String userId) async {
    final String id = userId.trim();
    if (id.isEmpty) return const <TeamModel>[];
    final snapshot = await _db
        .collection(hkzTeams)
        .where('teamLeaderId', isEqualTo: id)
        .get();
    final teams = snapshot.docs
        .map((d) => TeamModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return teams;
  }

  static Future<List<ProblemModel>> getActiveProblemsByDepartment({
    required String orgId,
    required String departmentCode,
  }) async {
    final snapshot = await _db
        .collection(hkzProblems)
        .where('orgId', isEqualTo: orgId)
        .where('departmentCode', isEqualTo: departmentCode.trim().toUpperCase())
        .where('status', isEqualTo: 'active')
        .get();
    final problems = snapshot.docs
        .map((d) => ProblemModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    problems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return problems;
  }

  /// All active problems for a college (any department).
  static Future<List<ProblemModel>> getActiveProblemsByCollege(String orgId) async {
    final snapshot = await _db
        .collection(hkzProblems)
        .where('orgId', isEqualTo: orgId)
        .where('status', isEqualTo: 'active')
        .get();
    final problems = snapshot.docs
        .map((d) => ProblemModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    problems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return problems;
  }

  static Future<List<ProblemModel>> getProblemModelsByCollege(String orgId) async {
    final snapshot = await _db.collection(hkzProblems).where('orgId', isEqualTo: orgId).get();
    final items = snapshot.docs
        .map((d) => ProblemModel.fromMap(d.id, d.data()))
        .toList(growable: false);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<List<Map<String, dynamic>>> getProblemStatementsByCollege(String orgId) async {
    final snapshot = await _db
        .collection(hkzProblems)
        .where('orgId', isEqualTo: orgId)
        .get();
    final items = snapshot.docs
        .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
        .toList(growable: false);
    items.sort((a, b) {
      final aTs = a['createdAt'] as Timestamp?;
      final bTs = b['createdAt'] as Timestamp?;
      final aMs = aTs?.millisecondsSinceEpoch ?? 0;
      final bMs = bTs?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    return items;
  }

  static Future<Map<String, dynamic>> getDepartmentStats({
    required String orgId,
    required String department,
  }) async {
    final departmentCode = _resolveDepartmentCode(department);
    final usersSnapshot = await _db.collection(hkzUsers).where('orgId', isEqualTo: orgId).get();
    final ideasSnapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();

    int totalTeamMembers = 0;
    int totalIdeas = 0;
    int activeIdeas = 0;
    int submitted = 0;
    int underReview = 0;
    int evaluated = 0;

    for (final user in usersSnapshot.docs) {
      final data = user.data();
      if (!_matchesDepartmentCode(data, departmentCode)) continue;
      final role = ((data['role'] as String?) ?? '').trim();
      if (role == UserRole.teamMember.code) {
        totalTeamMembers++;
      }
    }

    for (final idea in ideasSnapshot.docs) {
      final data = idea.data();
      if (!_matchesDepartmentCode(data, departmentCode)) continue;
      totalIdeas++;
      final IdeaStatus status = IdeaStatus.fromRaw((data['status'] as String?) ?? IdeaStatus.submitted.value);
      if (status == IdeaStatus.submitted) {
        submitted++;
        activeIdeas++;
        if (((data['totalEvaluators'] as num?)?.toInt() ?? 0) > 0) {
          evaluated++;
        }
      }
    }

    final totalJudges = usersSnapshot.docs.where((doc) {
      final data = doc.data();
      final role = ((data['role'] as String?) ?? '').trim();
      return role == 'JUD' && _matchesDepartmentCode(data, departmentCode);
    }).length;

    return <String, dynamic>{
      'totalTeamMembers': totalTeamMembers,
      'totalIdeas': totalIdeas,
      'activeIdeas': activeIdeas,
      'totalJudges': totalJudges,
      'submittedIdeas': submitted,
      'underReviewIdeas': underReview,
      'evaluatedIdeas': evaluated,
    };
  }

  static Future<List<UserModel>> getDepartmentUsers({
    required String orgId,
    required String department,
    required List<String> roleCodes,
    int limit = 50,
  }) async {
    final departmentCode = _resolveDepartmentCode(department);
    final snapshot = await _db.collection(hkzUsers).where('orgId', isEqualTo: orgId).get();
    final users = snapshot.docs
        .map((doc) {
          final user = UserModel.fromMap(doc.data());
          if (user.userId.isNotEmpty) return user;
          return user.copyWith(userId: doc.id);
        })
        .where(
          (user) =>
              _resolveDepartmentCode(user.departmentCode).trim() == departmentCode &&
              roleCodes.contains(user.role.trim()) &&
              user.status == UserStatus.active,
        )
        .toList(growable: false);
    return users.take(limit).toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> getDepartmentProblems({
    required String orgId,
    required String department,
  }) async {
    final departmentCode = _resolveDepartmentCode(department);
    final snapshot = await _db.collection(hkzProblems).where('orgId', isEqualTo: orgId).get();
    final items = snapshot.docs
        .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
        .where((p) => _matchesDepartmentCode(p, departmentCode))
        .toList(growable: false);
    items.sort((a, b) {
      final aTs = a['createdAt'] as Timestamp?;
      final bTs = b['createdAt'] as Timestamp?;
      final aMs = aTs?.millisecondsSinceEpoch ?? 0;
      final bMs = bTs?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    return items;
  }

  static Future<List<Map<String, dynamic>>> getDepartmentIdeas({
    required String orgId,
    required String department,
  }) async {
    final departmentCode = _resolveDepartmentCode(department);
    final snapshot = await _db.collection(hkzIdeas).where('orgId', isEqualTo: orgId).get();
    final items = snapshot.docs
        .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
        .where((i) => IdeaDepartmentHelpers.matchesTeamDept(i, departmentCode))
        .toList(growable: false);
    items.sort((a, b) {
      final aTs = a['createdAt'] as Timestamp?;
      final bTs = b['createdAt'] as Timestamp?;
      final aMs = aTs?.millisecondsSinceEpoch ?? 0;
      final bMs = bTs?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    return items;
  }

  static Future<List<Map<String, dynamic>>> getDepartmentIdeasGroupedByProblem({
    required String orgId,
    required String department,
  }) async {
    final ideas = await getDepartmentIdeas(orgId: orgId, department: department);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final idea in ideas) {
      final key = ((idea['problemTitle'] as String?) ?? '').trim().isNotEmpty
          ? ((idea['problemTitle'] as String?) ?? '').trim()
          : (((idea['problemId'] as String?) ?? '').trim().isNotEmpty
              ? ((idea['problemId'] as String?) ?? '').trim()
              : 'Unmapped Problem');
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(idea);
    }
    return grouped.entries
        .map((e) => <String, dynamic>{'problem': e.key, 'ideas': e.value})
        .toList(growable: false);
  }

  static Future<ProblemModel?> fetchProblemById(String problemId) async {
    final id = problemId.trim();
    if (id.isEmpty) return null;
    final doc = await _db.collection(hkzProblems).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProblemModel.fromMap(doc.id, doc.data()!);
  }

  static Future<PaymentModel?> getPaymentByIdeaId(String ideaId) async {
    final id = ideaId.trim();
    if (id.isEmpty) return null;
    final primary = await _db.collection(hkzPayments).doc(id).get();
    if (primary.exists && primary.data() != null) {
      return PaymentModel.fromMap(primary.id, primary.data()!);
    }
    final legacy = await _db.collection(hkzPayments).where('ideaId', isEqualTo: id).limit(1).get();
    if (legacy.docs.isEmpty) return null;
    return PaymentModel.fromMap(legacy.docs.first.id, legacy.docs.first.data());
  }

  /// Links the signed-in Firebase user to their `hkzUsers` profile (used by Firestore rules).
  static Future<void> syncAuthUserMirror({
    required String firebaseAuthUid,
    required UserModel profile,
  }) async {
    final uid = firebaseAuthUid.trim();
    if (uid.isEmpty || profile.userId.trim().isEmpty) return;
    await _db.collection(hkzUserAuthMirror).doc(uid).set(<String, dynamic>{
      'linkedProfileId': profile.userId.trim(),
    }, SetOptions(merge: true));
  }

  static Future<List<PaymentModel>> getPaymentsByOrg(String orgId) async {
    final snap = await _db.collection(hkzPayments).where('orgId', isEqualTo: orgId).get();
    final list = snap.docs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList(growable: false);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// One payment document per idea: document id is [PaymentModel.ideaId].
  /// Creates new, or replaces a **rejected** record (legacy random doc ids are migrated away).
  static Future<String> saveIdeaPayment(PaymentModel payment) async {
    final ideaKey = payment.ideaId.trim();
    if (ideaKey.isEmpty) {
      throw StateError('ideaId is required for payment.');
    }
    final ref = _db.collection(hkzPayments).doc(ideaKey);
    var primary = await ref.get();
    if (!primary.exists) {
      final legacy = await _db.collection(hkzPayments).where('ideaId', isEqualTo: ideaKey).limit(1).get();
      if (legacy.docs.isNotEmpty) {
        final leg = legacy.docs.first;
        if (leg.id != ideaKey) {
          final legPay = PaymentModel.fromMap(leg.id, leg.data());
          if (legPay.status == PaymentRecordStatus.verified) {
            throw StateError('Payment already verified for this idea.');
          }
          if (legPay.status == PaymentRecordStatus.pending) {
            throw StateError('Payment already pending for this idea.');
          }
          await leg.reference.delete();
        } else {
          primary = leg;
        }
      }
    }
    if (!primary.exists || primary.data() == null) {
      await ref.set(payment.copyWith(paymentId: ideaKey).toMap());
      return ideaKey;
    }
    final existing = PaymentModel.fromMap(primary.id, primary.data()!);
    if (existing.status == PaymentRecordStatus.verified) {
      throw StateError('Payment already verified for this idea.');
    }
    if (existing.status == PaymentRecordStatus.pending) {
      throw StateError('Payment already pending for this idea.');
    }
    await ref.set(
      payment
          .copyWith(
            paymentId: ideaKey,
            status: PaymentRecordStatus.pending,
            verifiedBy: '',
            verifiedAt: null,
          )
          .toMap(),
      SetOptions(merge: true),
    );
    return ideaKey;
  }

  static Future<void> verifyIdeaPayment({
    required String paymentId,
    required String coordinatorId,
    String? remarks,
  }) async {
    final legRef = _db.collection(hkzPayments).doc(paymentId);
    final legSnap = await legRef.get();
    if (!legSnap.exists || legSnap.data() == null) {
      throw StateError('Payment not found.');
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(legSnap.data()!);
    final ideaId = ((data['ideaId'] as String?) ?? '').trim();
    if (ideaId.isEmpty) throw StateError('Invalid payment payload.');

    final String participationId = ((data['participationId'] as String?) ?? '').trim();
    final String ideathonId = ((data['ideathonId'] as String?) ?? '').trim();
    final bool isEventPayment = participationId.isNotEmpty || ideathonId.isNotEmpty;

    final statusUpdate = <String, dynamic>{
      'status': PaymentRecordStatus.verified.value,
      'verifiedBy': coordinatorId,
      'verifiedAt': FieldValue.serverTimestamp(),
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    };

    if (isEventPayment) {
      // Event-scoped payments keep their own document id so the same idea
      // can have independent payments across events.
      statusUpdate['paymentId'] = legRef.id;
      await legRef.update(statusUpdate);
    } else {
      final canonRef = _db.collection(hkzPayments).doc(ideaId);
      final batch = _db.batch();
      statusUpdate['paymentId'] = ideaId;
      if (legRef.id != ideaId) {
        final merged = Map<String, dynamic>.from(data)..addAll(statusUpdate);
        batch.delete(legRef);
        batch.set(canonRef, merged);
      } else {
        batch.update(canonRef, statusUpdate);
      }
      await batch.commit();
    }

    await _syncIdeathonParticipationAfterPayment(
      participationId: participationId,
      ideathonId: ideathonId,
      ideaId: ideaId,
      paymentStatus: PaymentRecordStatus.verified,
    );
  }

  static Future<void> rejectIdeaPayment({
    required String paymentId,
    required String coordinatorId,
    String? remarks,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _db.collection(hkzPayments).doc(paymentId);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw StateError('Payment not found.');
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(snap.data()!);
    await ref.update(<String, dynamic>{
      'status': PaymentRecordStatus.rejected.value,
      'verifiedBy': coordinatorId,
      'verifiedAt': FieldValue.serverTimestamp(),
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
    await _syncIdeathonParticipationAfterPayment(
      participationId: ((data['participationId'] as String?) ?? '').trim(),
      ideathonId: ((data['ideathonId'] as String?) ?? '').trim(),
      ideaId: ((data['ideaId'] as String?) ?? '').trim(),
      paymentStatus: PaymentRecordStatus.rejected,
    );
  }

  /// Mirrors idea payment status onto any linked Ideathon membership row.
  static Future<void> _syncIdeathonParticipationAfterPayment({
    required String participationId,
    required String ideathonId,
    required String ideaId,
    required PaymentRecordStatus paymentStatus,
  }) async {
    String id = participationId.trim();
    if (id.isEmpty && ideathonId.trim().isNotEmpty && ideaId.trim().isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection(hkzIdeathonParticipations)
          .where('ideathonId', isEqualTo: ideathonId.trim())
          .where('ideaId', isEqualTo: ideaId.trim())
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) id = snap.docs.first.id;
    }
    if (id.isEmpty) return;
    await _db.collection(hkzIdeathonParticipations).doc(id).update(<String, dynamic>{
      'paymentStatus': paymentStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
