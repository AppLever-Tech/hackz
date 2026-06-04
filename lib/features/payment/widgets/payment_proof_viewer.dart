import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/models/attachment_model.dart';
import 'package:hackz/shared/feedback/feedback.dart';
import 'package:hackz/shared/inputs/network_image_compat.dart';
import 'package:hackz/widgets/attachment_viewer.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';

class PaymentProofViewer extends StatelessWidget {
  const PaymentProofViewer({
    super.key,
    required this.payment,
    required this.attachments,
    this.onOpenGallery,
    this.readOnly = false,
  });

  final PaymentModel payment;
  final List<AttachmentModel> attachments;
  final VoidCallback? onOpenGallery;
  final bool readOnly;

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
            readOnly ? _legacyProofReadOnly(context) : _legacyProofActions(context),
        ],
      ],
    );
  }

  Widget _legacyProofReadOnly(BuildContext context) {
    final String url = payment.paymentProofUrl.trim();
    final Uri? uri = Uri.tryParse(url);
    final bool isImage = uri != null &&
        (uri.path.toLowerCase().endsWith('.png') ||
            uri.path.toLowerCase().endsWith('.jpg') ||
            uri.path.toLowerCase().endsWith('.jpeg') ||
            uri.path.toLowerCase().endsWith('.webp'));

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: NetworkImageCompat(
            url: url,
            fit: BoxFit.cover,
            logTag: 'PaymentProof',
            errorBuilder: (_) => _legacyProofUrlText(url),
          ),
        ),
      );
    }
    return _legacyProofUrlText(url);
  }

  Widget _legacyProofUrlText(String url) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SelectableText(
        url,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
      ),
    );
  }

  Widget _legacyProofActions(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onOpenGallery ??
          () {
            FeedbackService.showInfo(
              context,
              title: 'Payment proof URL',
              message: payment.paymentProofUrl,
            );
          },
      icon: const Icon(AppIcons.preview),
      label: const Text('Open proof'),
    );
  }
}
