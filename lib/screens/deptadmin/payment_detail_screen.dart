import 'package:flutter/material.dart';

import '../../utils/department_payments_service.dart';
import '../../widgets/payments/payment_detail_pane.dart';

/// Embedded payment detail view (used inside dept admin dashboard body).
class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({
    super.key,
    required this.detail,
    required this.onBack,
  });

  final DepartmentPaymentDetail detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text('Back to payments'),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: PaymentDetailPane(detail: detail),
          ),
        ),
      ],
    );
  }
}
