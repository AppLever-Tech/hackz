import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/payment_finance_helpers.dart';
import '../shared/entity_reference_row.dart';
import 'payment_workspace.dart';
import 'payment_workspace_loader.dart';

class PaymentSummarySection extends StatelessWidget {
  const PaymentSummarySection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final payment = vm.payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF99F6E4)),
          ),
          child: const Row(
            children: <Widget>[
              Icon(AppIcons.verification, size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure payment record · read-only audit view',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          PaymentFinanceHelpers.formatCurrency(payment.amount),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        EntityReferenceRow(
          leadingIcon: AppIcons.clock,
          label: 'Payment date',
          value: PaymentFinanceHelpers.formatDate(payment.createdAt),
        ),
        EntityReferenceRow(
          leadingIcon: AppIcons.student,
          label: 'Payer',
          value: vm.payerName,
          workspaceEntityLabel: 'user',
          onOpenWorkspace: payment.paidByStudentId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openUserFromPayment(context, vm),
        ),
        EntityReferenceRow(
          leadingIcon: AppIcons.ideas,
          label: 'Idea',
          value: vm.ideaTitle,
          workspaceEntityLabel: 'idea',
          onOpenWorkspace: payment.ideaId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openIdeaFromPayment(context, vm),
        ),
        EntityReferenceRow(
          leadingIcon: AppIcons.teams,
          label: 'Team',
          value: vm.teamName,
          workspaceEntityLabel: 'team',
          onOpenWorkspace: payment.teamId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openTeamFromPayment(context, vm),
        ),
        EntityReferenceRow(
          leadingIcon: AppIcons.departments,
          label: 'Department',
          value: vm.departmentLabel.trim().isEmpty ? '—' : vm.departmentLabel.trim(),
        ),
      ],
    );
  }
}
