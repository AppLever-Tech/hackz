import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../models/payment_model.dart';
import '../../utils/payment_finance_helpers.dart';
import '../../screens/common/app_dialog_template.dart';
import '../attachment_viewer.dart';
import '../responsive/responsive_alert_dialog.dart';

class PaymentProofViewer extends StatelessWidget {
  const PaymentProofViewer({
    super.key,
    required this.payment,
    required this.attachments,
    this.onOpenGallery,
  });

  final PaymentModel payment;
  final List<AttachmentModel> attachments;
  final VoidCallback? onOpenGallery;

  bool get _hasProof => payment.paymentProofUrl.trim().isNotEmpty || attachments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(AppIcons.attachmentImage, color: Color(0xFF0891B2), size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Payment proof', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ),
            Text(
              'Uploaded ${PaymentFinanceHelpers.formatDate(payment.createdAt)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_hasProof)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(AppIcons.info, color: Color(0xFFB45309)),
                SizedBox(width: 10),
                Expanded(child: Text('No payment proof uploaded yet.', style: TextStyle(color: Color(0xFF92400E)))),
              ],
            ),
          )
        else ...<Widget>[
          if (attachments.isNotEmpty)
            AttachmentPreviewRow(
              entityType: AttachmentEntityType.payment,
              entityId: payment.paymentId,
              title: 'Screenshots & files',
            )
          else if (payment.paymentProofUrl.trim().isNotEmpty)
            _legacyProofActions(context),
        ],
      ],
    );
  }

  Widget _legacyProofActions(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onOpenGallery ??
          () {
            showDialog<void>(
              context: context,
              builder: (_) => ResponsiveAlertDialog(
                title: const Text('Payment proof URL'),
                widthPreset: DialogWidthPreset.standard,
                content: SelectableText(payment.paymentProofUrl),
                actions: <Widget>[
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                ],
              ),
            );
          },
      icon: const Icon(AppIcons.preview),
      label: const Text('Open proof'),
    );
  }
}
