import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_navigator.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../attachment/models/attachment_model.dart';
import '../../attachment/services/attachment_service.dart';
import '../models/payment_model.dart';

/// Opens the payment screenshot in the attachment or payment context workspace.
abstract final class PaymentProofLauncher {
  PaymentProofLauncher._();

  static Future<void> open(BuildContext context, PaymentModel payment) async {
    final List<AttachmentModel> attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.payment,
      entityId: payment.paymentId,
    );
    if (!context.mounted) return;
    if (attachments.length == 1) {
      WorkspaceNavigator.openAttachment(context, attachments.first.attachmentId);
      return;
    }
    if (attachments.isNotEmpty || payment.paymentProofUrl.trim().isNotEmpty) {
      WorkspaceNavigator.openPayment(context, payment.paymentId);
      return;
    }
    FeedbackService.showInfo(
      context,
      title: 'Payment proof',
      message: 'No payment proof uploaded yet.',
    );
  }
}
