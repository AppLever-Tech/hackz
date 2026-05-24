import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/payment_model.dart';
import '../../widgets/common/context_pill.dart';
import '../../widgets/common/context_pill_group.dart';
import '../../widgets/common/context_pill_theme.dart';
import '../../workspace/shared/entity_reference_row.dart';

class CoordinatorPaymentCard extends StatelessWidget {
  const CoordinatorPaymentCard({
    super.key,
    required this.payment,
    required this.problemNumber,
    this.onOpenProblem,
    this.onOpenTeam,
    this.onOpenPayment,
    required this.teamName,
    required this.studentName,
    this.onOpenStudent,
    required this.onViewScreenshot,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentModel payment;
  final String problemNumber;
  final VoidCallback? onOpenProblem;
  final VoidCallback? onOpenTeam;
  final VoidCallback? onOpenPayment;
  final String teamName;
  final String studentName;
  final VoidCallback? onOpenStudent;
  final VoidCallback onViewScreenshot;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = payment.status == PaymentRecordStatus.pending;
    final String problemLabel = problemNumber.isEmpty ? 'N/A' : problemNumber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (onOpenProblem != null)
                Expanded(
                  child: ContextPillGroup(
                    fieldLabel: 'Problem',
                    pillLabel: problemLabel,
                    semantic: ContextPillSemantic.problem,
                    onOpenWorkspace: onOpenProblem!,
                    compact: true,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    problemLabel,
                    style: const TextStyle(
                      color: Color(0xFF2E43C6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              _statusChip(payment.status),
            ],
          ),
          const SizedBox(height: 10),
          EntityReferenceRow(
            leadingIcon: AppIcons.teams,
            label: 'Team',
            value: teamName,
            semantic: ContextPillSemantic.team,
            onOpenWorkspace: onOpenTeam,
          ),
          EntityReferenceRow(
            leadingIcon: AppIcons.student,
            label: 'Student',
            value: studentName,
            dense: true,
            semantic: ContextPillSemantic.user,
            onOpenWorkspace: onOpenStudent,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Amount: ${payment.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (onOpenPayment != null)
                ContextPill(
                  label: 'Payment record',
                  semantic: ContextPillSemantic.payment,
                  onTap: onOpenPayment!,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: payment.paymentProofUrl.isEmpty ? null : onViewScreenshot,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text('View Screenshot'),
              ),
              if (pending) ...<Widget>[
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                ),
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

  Widget _statusChip(PaymentRecordStatus status) {
    final label = switch (status) {
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.verified => 'Verified',
      PaymentRecordStatus.rejected => 'Rejected',
    };
    final color = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFFFF1E4),
      PaymentRecordStatus.verified => const Color(0xFFE7F9F1),
      PaymentRecordStatus.rejected => const Color(0xFFFDECEC),
    };
    final fg = switch (status) {
      PaymentRecordStatus.pending => const Color(0xFFB56A11),
      PaymentRecordStatus.verified => const Color(0xFF177C50),
      PaymentRecordStatus.rejected => const Color(0xFFB93838),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
