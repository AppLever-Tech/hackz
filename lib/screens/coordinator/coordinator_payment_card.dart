import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import 'package:hackz/features/payment/services/payment_finance_helpers.dart';
import 'package:hackz/features/payment/widgets/payment_status_pill.dart';
import 'package:hackz/core/ui/common/entity_card_pills.dart';

import '../../core/responsive/responsive_helper.dart';
import '../../screens/common/dashboard_components.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

class CoordinatorPaymentCard extends StatelessWidget {
  const CoordinatorPaymentCard({
    super.key,
    required this.payment,
    required this.teamName,
    required this.ideaName,
    this.onOpenTeam,
    this.onOpenIdea,
    this.onOpenPayment,
    this.onOpenAttachments,
    this.attachmentCount = 0,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentModel payment;
  final String teamName;
  final String ideaName;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onOpenIdea;
  final VoidCallback? onOpenPayment;
  final VoidCallback? onOpenAttachments;
  final int attachmentCount;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bool pending = payment.status == PaymentRecordStatus.pending;
    final String teamLabel = teamName.trim().isEmpty ? 'Unnamed team' : teamName.trim();
    final String ideaLabel = ideaName.trim().isEmpty ? 'Idea not mapped' : ideaName.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onOpenTeam == null
                      ? Text(
                          teamLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : ContextPill(
                          label: teamLabel,
                          semantic: ContextPillSemantic.team,
                          onTap: onOpenTeam!,
                          compact: true,
                          fitContent: true,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                PaymentFinanceHelpers.formatCurrency(payment.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onOpenIdea == null
                      ? Text(
                          ideaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        )
                      : ContextPill(
                          label: ideaLabel,
                          semantic: ContextPillSemantic.idea,
                          onTap: onOpenIdea!,
                          compact: true,
                          fitContent: true,
                        ),
                ),
              ),
              PaymentStatusPill(status: payment.status, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          _buildFooterActions(context, pending: pending),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, {required bool pending}) {
    final Widget? paymentPill = onOpenPayment == null
        ? null
        : ContextPill(
            label: 'Payment details',
            semantic: ContextPillSemantic.payment,
            onTap: onOpenPayment!,
            compact: true,
            fitContent: true,
            allowHoverScale: false,
          );
    final Widget? attachmentsPill = onOpenAttachments == null
        ? null
        : EntityCardPills.workspace(
            _attachmentPillLabel(attachmentCount),
            ContextPillSemantic.generic,
            onOpenAttachments!,
            icon: AppIcons.attachments,
          );
    final Widget approveButton = FilledButton.icon(
      onPressed: onApprove,
      icon: const Icon(Icons.check_circle_outline, size: 16),
      label: const Text('Approve'),
    );
    final Widget rejectButton = OutlinedButton.icon(
      onPressed: onReject,
      icon: const Icon(Icons.cancel_outlined, size: 16),
      label: const Text('Reject'),
    );

    if (ResponsiveHelper.isMobile(context) && pending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (paymentPill != null) paymentPill,
              const Spacer(),
              if (attachmentsPill != null) attachmentsPill,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(child: approveButton),
              const SizedBox(width: 8),
              Expanded(child: rejectButton),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (paymentPill != null) paymentPill,
        const Spacer(),
        if (attachmentsPill != null) attachmentsPill,
        if (pending) ...<Widget>[
          const SizedBox(width: 8),
          approveButton,
          const SizedBox(width: 8),
          rejectButton,
        ],
      ],
    );
  }

  String _attachmentPillLabel(int count) {
    final resolved = count > 0 ? count : 1;
    return '$resolved Attachment${resolved == 1 ? '' : 's'}';
  }
}
