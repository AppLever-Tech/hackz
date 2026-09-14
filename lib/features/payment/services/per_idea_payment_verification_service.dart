import '../../ideathons/services/ideathon_service.dart';
import '../../organization/services/commercial_access.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../models/payment_model.dart';
import '../../../utils/firestore_utils.dart';

/// PER_IDEA idea payment approval — Hackz org admin only (application layer).
abstract final class PerIdeaPaymentVerificationService {
  PerIdeaPaymentVerificationService._();

  static void assertCanVerify(UserModel actor) {
    if (UserRole.fromCode(actor.role) != UserRole.orgAdmin) {
      throw StateError('Only a Hackz Organisation Admin can verify idea payments.');
    }
  }

  static Future<void> verify({
    required PaymentModel payment,
    required UserModel actor,
  }) async {
    assertCanVerify(actor);
    if (!await CommercialAccess.requiresIdeaPaymentForOrg(actor.orgId)) return;
    await IdeathonService.confirmTeamLeaderPayment(payment: payment, coordinator: actor);
  }

  static Future<void> reject({
    required PaymentModel payment,
    required UserModel actor,
    String? remarks,
  }) async {
    assertCanVerify(actor);
    if (!await CommercialAccess.requiresIdeaPaymentForOrg(actor.orgId)) return;
    await FirestoreUtils.rejectIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: actor.userId,
      remarks: remarks,
    );
  }
}
