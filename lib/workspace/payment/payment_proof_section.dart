import 'package:flutter/material.dart';

import '../../widgets/payments/payment_proof_viewer.dart';
import 'payment_workspace_loader.dart';

class PaymentProofSection extends StatelessWidget {
  const PaymentProofSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Payment proof',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: PaymentProofViewer(
            payment: vm.payment,
            attachments: vm.proofAttachments,
            readOnly: true,
          ),
        ),
      ],
    );
  }
}
