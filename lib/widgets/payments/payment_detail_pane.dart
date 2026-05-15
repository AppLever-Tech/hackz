import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/payment_model.dart';
import '../../utils/department_payments_service.dart';
import '../../utils/payment_finance_helpers.dart';
import 'payment_proof_viewer.dart';
import 'payment_status_pill.dart';
import 'team_contribution_section.dart';
import 'verification_timeline_widget.dart';

class PaymentDetailPane extends StatelessWidget {
  const PaymentDetailPane({
    super.key,
    required this.detail,
  });

  final DepartmentPaymentDetail detail;

  @override
  Widget build(BuildContext context) {
    final payment = detail.contribution.payment;
    final contribution = detail.contribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(AppIcons.payments, color: Color(0xFF0891B2), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Payment summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
            PaymentStatusPill(status: payment.status, showAttentionDot: contribution.needsAttention),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          PaymentFinanceHelpers.formatCurrency(payment.amount),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        _summaryRow('Paid on', PaymentFinanceHelpers.formatDate(payment.createdAt)),
        if (payment.verifiedAt != null)
          _summaryRow(
            payment.status == PaymentRecordStatus.rejected ? 'Rejected on' : 'Verified on',
            PaymentFinanceHelpers.formatDate(payment.verifiedAt!),
          ),
        _summaryRow('Coordinator', contribution.coordinatorName),
        if (payment.transactionId?.trim().isNotEmpty == true)
          _summaryRow('Transaction ID', payment.transactionId!.trim()),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        TeamContributionSection.fromModels(
          team: detail.team,
          mentorName: contribution.mentorName,
          students: detail.students,
          idea: detail.idea,
          problem: detail.problem,
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        PaymentProofViewer(payment: payment, attachments: detail.proofAttachments),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        const Row(
          children: <Widget>[
            Icon(AppIcons.clock, color: Color(0xFF6A38FF), size: 18),
            SizedBox(width: 8),
            Text('Verification timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        VerificationTimelineWidget(payment: payment, remarks: payment.remarks),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _insightTile(
                icon: AppIcons.insights,
                label: 'Dept. contribution',
                value: '${detail.departmentContributionPercent.toStringAsFixed(1)}%',
                color: const Color(0xFF6A38FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _insightTile(
                icon: AppIcons.payments,
                label: 'Trend',
                value: detail.paymentTrendLabel,
                color: const Color(0xFF0891B2),
                compactValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _insightTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool compactValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: compactValue ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compactValue ? 12 : 16,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
