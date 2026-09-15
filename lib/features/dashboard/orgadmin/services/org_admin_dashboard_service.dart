import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/hackz_firebase.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../../payment/models/payment_model.dart';
import '../../../../utils/firestore_utils.dart';
import 'tenant_setup_readiness_service.dart';

/// PER_IDEA payment approval counts for orgAdmin dashboard (tenant hkzPayments).
class OrgAdminPaymentApprovalCounts {
  const OrgAdminPaymentApprovalCounts({
    this.pending = 0,
    this.verified = 0,
    this.rejected = 0,
  });

  final int pending;
  final int verified;
  final int rejected;

  static const OrgAdminPaymentApprovalCounts empty = OrgAdminPaymentApprovalCounts();
}

class OrgAdminDashboardData {
  const OrgAdminDashboardData({
    required this.readiness,
    required this.paymentCounts,
  });

  final TenantSetupReadiness readiness;
  final OrgAdminPaymentApprovalCounts paymentCounts;
}

abstract final class OrgAdminDashboardService {
  OrgAdminDashboardService._();

  static Future<OrgAdminDashboardData> load(String orgId) async {
    final String id = orgId.trim();
    final Future<TenantSetupReadiness> readinessFuture = TenantSetupReadinessService.load(id);
    final Future<OrgAdminPaymentApprovalCounts> paymentsFuture = _loadPaymentCounts(id);
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      readinessFuture,
      paymentsFuture,
    ]);
    return OrgAdminDashboardData(
      readiness: results[0] as TenantSetupReadiness,
      paymentCounts: results[1] as OrgAdminPaymentApprovalCounts,
    );
  }

  static Future<OrgAdminPaymentApprovalCounts> _loadPaymentCounts(String orgId) async {
    if (orgId.isEmpty) return OrgAdminPaymentApprovalCounts.empty;
    final QuerySnapshot<Map<String, dynamic>> snap = await HackzFirebase.current.firestore
        .collection(FirestoreUtils.hkzPayments)
        .where('orgId', isEqualTo: orgId)
        .get();
    int pending = 0;
    int verified = 0;
    int rejected = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final PaymentRecordStatus status =
          PaymentRecordStatus.fromRaw((doc.data()['status'] as String?) ?? '');
      switch (status) {
        case PaymentRecordStatus.pending:
          pending++;
        case PaymentRecordStatus.verified:
          verified++;
        case PaymentRecordStatus.rejected:
          rejected++;
      }
    }
    return OrgAdminPaymentApprovalCounts(pending: pending, verified: verified, rejected: rejected);
  }

  static bool showPaymentApprovals(OrganizationCommercialPlan plan) =>
      plan == OrganizationCommercialPlan.perIdea;
}
