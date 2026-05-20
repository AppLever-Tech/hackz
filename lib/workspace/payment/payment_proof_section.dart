import 'package:flutter/material.dart';

import '../core/workspace_attachments_summary.dart';
import 'payment_workspace_loader.dart';

class PaymentProofSection extends StatelessWidget {
  const PaymentProofSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final List<String> footer = vm.hasLegacyProofUrl && vm.proofAttachmentCounts.isEmpty
        ? const <String>['Legacy proof reference on file (not shown in workspace)']
        : const <String>[];

    return WorkspaceAttachmentsSummary(
      title: 'Payment proof',
      counts: vm.proofAttachmentCounts,
      emptyMessage: vm.hasLegacyProofUrl
          ? 'No structured proof files; see note below.'
          : 'No payment proof uploaded yet.',
      footerLines: footer,
    );
  }
}
