import 'package:cloud_firestore/cloud_firestore.dart';

import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/evaluator_source.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Loads and classifies users eligible for evaluation assignment.
class EvaluatorCatalogService {
  EvaluatorCatalogService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<List<UserModel>> loadEvaluators({
    required String orgId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzUsers)
        .where('orgId', isEqualTo: orgId)
        .where('role', isEqualTo: UserRole.judge.code)
        .get();

    final Map<String, UserModel> byId = <String, UserModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      UserModel user = UserModel.fromMap(doc.data());
      if (user.userId.trim().isEmpty) {
        user = user.copyWith(userId: doc.id);
      }
      byId[user.userId] = user;
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
    return EvaluatorSource.judge;
  }

  static String roleBadgeLabel(UserModel user) => 'Judge';

  static bool matchesFilter(UserModel user, EvaluatorListFilter filter) {
    switch (filter) {
      case EvaluatorListFilter.all:
        return true;
      case EvaluatorListFilter.judges:
        return sourceFor(user) == EvaluatorSource.judge;
    }
  }

  static bool matchesSearch(UserModel user, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return user.displayName.toLowerCase().contains(q) ||
        user.email.toLowerCase().contains(q);
  }
}
