import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/models/idea_model.dart';
import 'ideathon_settings_service.dart';

class IdeathonReadiness {
  const IdeathonReadiness({
    required this.shortlistedCount,
    required this.requiredCount,
  });

  final int shortlistedCount;
  final int requiredCount;

  bool get isReady => shortlistedCount >= requiredCount;
  int get remaining => (requiredCount - shortlistedCount).clamp(0, requiredCount);
}

/// Computes whether a department has enough shortlisted ideas for an ideathon.
abstract final class IdeathonReadinessService {
  IdeathonReadinessService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<IdeathonReadiness> compute({
    required String orgId,
    required String departmentCode,
  }) async {
    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final int required = IdeathonSettingsService.minShortlistedIdeasRequired(orgId);
    final String dept = departmentCode.trim().toUpperCase();

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: orgId.trim())
        .where('status', isEqualTo: IdeaStatus.shortlisted.value)
        .get();

    final int count = snap.docs.where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (dept.isEmpty) return true;
      return idea.problemDepartmentCode.trim().toUpperCase() == dept;
    }).length;

    return IdeathonReadiness(shortlistedCount: count, requiredCount: required);
  }
}
