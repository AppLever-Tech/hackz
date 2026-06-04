import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import 'package:hackz/features/payment/services/payment_finance_helpers.dart';
import 'package:hackz/features/payment/widgets/payment_status_pill.dart';
import 'package:hackz/widgets/common/entity_card_pills.dart';

import '../../screens/common/dashboard_components.dart';
import '../../workspace/workspace.dart';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (onOpenPayment != null)
                ContextPill(
                  label: 'Payment details',
                  semantic: ContextPillSemantic.payment,
                  onTap: onOpenPayment!,
                  compact: true,
                  fitContent: true,
                ),
              const Spacer(),
              if (onOpenAttachments != null)
                EntityCardPills.workspace(
                  _attachmentPillLabel(attachmentCount),
                  ContextPillSemantic.generic,
                  onOpenAttachments!,
                  icon: AppIcons.attachments,
                ),
              if (pending) ...<Widget>[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _attachmentPillLabel(int count) {
    final resolved = count > 0 ? count : 1;
    return '$resolved Attachment${resolved == 1 ? '' : 's'}';
  }
}
