import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/core/workspace/workspace_attachments_panel.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';

/// Read-only payment proof list with per-file attachment workspace navigation.
class PaymentProofPanel extends StatelessWidget {
  const PaymentProofPanel({
    super.key,
    required this.payment,
    required this.attachments,
    this.showDetailHeader = false,
  });

  final PaymentModel payment;
  final List<AttachmentModel> attachments;
  final bool showDetailHeader;

  bool get _hasLegacyProofUrl => payment.paymentProofUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showDetailHeader) ...<Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.attachmentImage, color: Color(0xFF0891B2), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Payment proof',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
              Text(
                'Uploaded ${PaymentFinanceHelpers.formatDate(payment.createdAt)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _buildProofBody(),
      ],
    );
  }

  Widget _buildProofBody() {
    if (attachments.isEmpty && !_hasLegacyProofUrl) {
      if (showDetailHeader) {
        return const Text(
          'No payment proof uploaded yet.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        );
      }
      return const WorkspaceAttachmentsPanel(
        attachments: <AttachmentModel>[],
        title: 'Payment proof',
        emptyMessage: 'No payment proof uploaded yet.',
        showTypeSummary: false,
      );
    }

    if (attachments.isEmpty && _hasLegacyProofUrl) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!showDetailHeader)
            const Text(
              'Payment proof',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          if (!showDetailHeader) const SizedBox(height: 10),
          const Text(
            'Legacy proof reference on file (not shown in workspace).',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return WorkspaceAttachmentsPanel(
      title: showDetailHeader ? '' : 'Payment proof',
      attachments: attachments,
      emptyMessage: 'No payment proof uploaded yet.',
    );
  }
}
