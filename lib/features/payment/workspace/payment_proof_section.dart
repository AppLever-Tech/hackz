import 'package:flutter/material.dart';

import 'package:hackz/models/attachment_model.dart';
import 'package:hackz/workspace/core/workspace_attachments_panel.dart';
import 'payment_workspace_loader.dart';

class PaymentProofSection extends StatelessWidget {
  const PaymentProofSection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.proofAttachments.isEmpty && !vm.hasLegacyProofUrl) {
      return const WorkspaceAttachmentsPanel(
        attachments: <AttachmentModel>[],
        title: 'Payment proof',
        emptyMessage: 'No payment proof uploaded yet.',
        showTypeSummary: false,
      );
    }

    if (vm.proofAttachments.isEmpty && vm.hasLegacyProofUrl) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Payment proof',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Legacy proof reference on file (not shown in workspace).',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return WorkspaceAttachmentsPanel(
      title: 'Payment proof',
      attachments: vm.proofAttachments,
      emptyMessage: 'No payment proof uploaded yet.',
    );
  }
}
