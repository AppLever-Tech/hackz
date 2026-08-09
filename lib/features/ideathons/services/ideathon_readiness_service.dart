import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import 'ideathon_settings_service.dart';

class IdeathonReadiness {
  const IdeathonReadiness({
    required this.eligibleCount,
    required this.requiredCount,
  });

  final int eligibleCount;
  final int requiredCount;

  bool get isReady => eligibleCount >= requiredCount;
  int get remaining => (requiredCount - eligibleCount).clamp(0, requiredCount);
}

/// Computes whether a department has enough Ideathon-eligible ideas.
abstract final class IdeathonReadinessService {
  IdeathonReadinessService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<IdeathonReadiness> compute({
    required String orgId,
    required String departmentCode,
  }) async {
    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final int required = IdeathonSettingsService.minIdeasRequiredForIdeathon(orgId);
    final String dept = departmentCode.trim().toUpperCase();

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: orgId.trim())
        .get();

    final int count = snap.docs.where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (!IdeaStatusHelpers.isEligibleForIdeathon(idea.status)) return false;
      if (dept.isEmpty) return true;
      return idea.problemDepartmentCode.trim().toUpperCase() == dept;
    }).length;

    return IdeathonReadiness(eligibleCount: count, requiredCount: required);
  }
}
