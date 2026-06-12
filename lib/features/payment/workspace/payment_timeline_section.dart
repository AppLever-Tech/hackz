import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';
import '../widgets/verification_timeline_widget.dart';
import 'payment_workspace_loader.dart';

class PaymentTimelineSection extends StatelessWidget {
  const PaymentTimelineSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final payment = vm.payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(AppIcons.clock, color: Color(0xFF0891B2), size: 18),
            SizedBox(width: 8),
            Text(
              'Verification timeline',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        VerificationTimelineWidget(payment: payment, remarks: payment.remarks),
        const SizedBox(height: 12),
        const Text(
          'Audit metadata',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        _metaTile(
          icon: AppIcons.verification,
          label: 'Verification status',
          value: PaymentFinanceHelpers.statusLabel(payment.status),
        ),
        _metaTile(
          icon: AppIcons.payments,
          label: 'Transaction reference',
          value: _transactionRef(payment),
        ),
        if (payment.verifiedAt != null)
          _metaTile(
            icon: payment.status == PaymentRecordStatus.rejected ? AppIcons.statusRejected : AppIcons.workflowApproved,
            label: payment.status == PaymentRecordStatus.rejected ? 'Rejected on' : 'Verified on',
            value: PaymentFinanceHelpers.formatDate(payment.verifiedAt!),
          ),
        if (vm.verifierName.trim().isNotEmpty && vm.verifierName != '—')
          _metaTile(
            icon: AppIcons.coordinator,
            label: 'Reviewed by',
            value: vm.verifierName,
          ),
      ],
    );
  }

  static String _transactionRef(PaymentModel payment) {
    final String txn = payment.transactionId?.trim() ?? '';
    if (txn.isNotEmpty) return txn;
    final String id = payment.paymentId.trim();
    return id.isEmpty ? '—' : id;
  }

  static Widget _metaTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
