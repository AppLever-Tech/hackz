import 'package:flutter/material.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';

class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({
    super.key,
    required this.status,
    this.compact = false,
    this.showAttentionDot = false,
  });

  final PaymentRecordStatus status;
  final bool compact;
  final bool showAttentionDot;

  @override
  Widget build(BuildContext context) {
    final color = PaymentFinanceHelpers.statusColor(status);
    final bg = PaymentFinanceHelpers.statusBackground(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(PaymentFinanceHelpers.statusIcon(status), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            PaymentFinanceHelpers.statusLabel(status),
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (showAttentionDot) ...<Widget>[
            const SizedBox(width: 5),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ],
      ),
    );
  }
}
