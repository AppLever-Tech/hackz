import 'package:cloud_firestore/cloud_firestore.dart';

import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/evaluator_source.dart';

/// Loads and classifies users eligible for evaluation assignment.
class EvaluatorCatalogService {
  EvaluatorCatalogService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> allowFacultyAsJudges(String orgId) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
    final Object? raw =
        OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.allowFacultyAsJudges];
    if (raw is bool) return raw;
    return true;
  }

  static Future<List<UserModel>> loadEvaluators({
    required String orgId,
    bool? allowFacultyAsJudges,
  }) async {
    final bool includeFaculty =
        allowFacultyAsJudges ?? await EvaluatorCatalogService.allowFacultyAsJudges(orgId);

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries =
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
      _db
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.judge.code)
          .get(),
    ];
    if (includeFaculty) {
      queries.add(
        _db
            .collection(FirestoreUtils.hkzUsers)
            .where('orgId', isEqualTo: orgId)
            .where('role', isEqualTo: UserRole.faculty.code)
            .get(),
      );
    }

    final List<QuerySnapshot<Map<String, dynamic>>> results =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(queries);

    final Map<String, UserModel> byId = <String, UserModel>{};
    for (final QuerySnapshot<Map<String, dynamic>> snap in results) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) {
          user = user.copyWith(userId: doc.id);
        }
        byId[user.userId] = user;
      }
    }

    final List<UserModel> evaluators = byId.values.toList(growable: false)
      ..sort((UserModel a, UserModel b) {
        final int byName = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        if (byName != 0) return byName;
        return a.userId.compareTo(b.userId);
      });
    return evaluators;
  }

  static EvaluatorSource sourceFor(UserModel user) {
    if (user.hasRoleCode(UserRole.judge.code) || user.role.trim() == UserRole.judge.code) {
      return EvaluatorSource.judge;
    }
    return EvaluatorSource.faculty;
  }

  static String roleBadgeLabel(UserModel user) {
    if (sourceFor(user) == EvaluatorSource.judge) return 'Judge';
    return 'Faculty • Internal';
  }

  static bool matchesFilter(UserModel user, EvaluatorListFilter filter) {
    switch (filter) {
      case EvaluatorListFilter.all:
        return true;
      case EvaluatorListFilter.judges:
        return sourceFor(user) == EvaluatorSource.judge;
      case EvaluatorListFilter.faculty:
        return sourceFor(user) == EvaluatorSource.faculty;
    }
  }

  static bool matchesSearch(UserModel user, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return user.displayName.toLowerCase().contains(q) ||
        user.email.toLowerCase().contains(q);
  }
}
