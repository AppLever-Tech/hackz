import 'package:flutter/material.dart';

import '../widgets/payment_proof_panel.dart';
import 'payment_workspace_loader.dart';

class PaymentProofSection extends StatelessWidget {
  const PaymentProofSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return PaymentProofPanel(
      payment: vm.payment,
      attachments: vm.proofAttachments,
    );
  }
}
