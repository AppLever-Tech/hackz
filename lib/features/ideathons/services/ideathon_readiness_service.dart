import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../payment/models/payment_model.dart';
import 'ideathon_settings_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

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

/// Counts submitted ideas with verified payment vs org minimum for Ideathon create.
abstract final class IdeathonReadinessService {
  IdeathonReadinessService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<IdeathonReadiness> compute({
    required String orgId,
    required String departmentCode,
  }) async {
    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final int required = IdeathonSettingsService.minimumIdeasForIdeathon(orgId);
    final String org = orgId.trim();
    final String dept = departmentCode.trim().toUpperCase();

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: org)
        .get();

    final List<PaymentModel> payments = await FirestoreUtils.getPaymentsByOrg(org);
    final Set<String> verifiedIdeaIds = payments
        .where((PaymentModel p) => p.status == PaymentRecordStatus.verified)
        .map((PaymentModel p) => p.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    final int count = snap.docs.where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (!IdeaStatusHelpers.isEligibleForIdeathon(idea.status)) return false;
      if (!verifiedIdeaIds.contains(idea.ideaId.trim())) return false;
      if (dept.isEmpty) return true;
      return idea.problemDepartmentCode.trim().toUpperCase() == dept;
    }).length;

    return IdeathonReadiness(eligibleCount: count, requiredCount: required);
  }
}
