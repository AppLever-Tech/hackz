import 'package:flutter/material.dart';

import '../../models/payment_model.dart';

class CoordinatorPaymentCard extends StatelessWidget {
  const CoordinatorPaymentCard({
    super.key,
    required this.payment,
    required this.problemNumber,
    required this.teamName,
    required this.studentName,
    required this.onViewScreenshot,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentModel payment;
  final String problemNumber;
  final String teamName;
  final String studentName;
  final VoidCallback onViewScreenshot;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = payment.status == PaymentRecordStatus.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  problemNumber.isEmpty ? 'N/A' : problemNumber,
                  style: const TextStyle(
                    color: Color(0xFF2E43C6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _statusChip(payment.status),
            ],
          ),
          const SizedBox(height: 10),
          Text('Team: $teamName', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Student: $studentName', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Amount: ${payment.amount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: payment.paymentProofUrl.isEmpty ? null : onViewScreenshot,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text('View Screenshot'),
              ),
              if (pending) ...<Widget>[
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(PaymentRecordStatus status) {
    final label = switch (status) {
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.verified => 'Verified',
      PaymentRecordStatus.rejected => 'Rejected',
    };
    final color = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFFFF1E4),
      PaymentRecordStatus.verified => const Color(0xFFE7F9F1),
      PaymentRecordStatus.rejected => const Color(0xFFFDECEC),
    };
    final fg = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFB56A11),
      PaymentRecordStatus.verified => const Color(0xFF177C50),
      PaymentRecordStatus.rejected => const Color(0xFFB93838),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
