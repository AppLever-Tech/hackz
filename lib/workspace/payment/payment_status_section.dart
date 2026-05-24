import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../utils/payment_finance_helpers.dart';
import '../../widgets/payments/payment_status_pill.dart';
import 'payment_workspace_loader.dart';

class PaymentStatusSection extends StatelessWidget {
  const PaymentStatusSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final payment = vm.payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Payment status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PaymentFinanceHelpers.statusBackground(payment.status),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: PaymentFinanceHelpers.statusColor(payment.status).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    PaymentStatusPill(
                      status: payment.status,
                      showAttentionDot: vm.needsAttention,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusNarrative(payment.status),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _statusNarrative(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.pending => 'Awaiting coordinator verification. No changes can be made from this audit view.',
      PaymentRecordStatus.verified => 'Payment verified and recorded for department collection.',
      PaymentRecordStatus.rejected => 'Payment rejected. Review remarks in the timeline below.',
    };
  }
}
