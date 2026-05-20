import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/payment_finance_helpers.dart';
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
        _row(
          context,
          icon: AppIcons.clock,
          label: 'Payment date',
          value: PaymentFinanceHelpers.formatDate(payment.createdAt),
        ),
        _linkRow(
          context,
          icon: AppIcons.student,
          label: 'Payer',
          value: vm.payerName,
          onTap: payment.paidByStudentId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openUserFromPayment(context, vm),
        ),
        _linkRow(
          context,
          icon: AppIcons.ideas,
          label: 'Idea',
          value: vm.ideaTitle,
          onTap: payment.ideaId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openIdeaFromPayment(context, vm),
        ),
        _linkRow(
          context,
          icon: AppIcons.teams,
          label: 'Team',
          value: vm.teamName,
          onTap: payment.teamId.trim().isEmpty
              ? null
              : () => PaymentWorkspace.openTeamFromPayment(context, vm),
        ),
        _row(
          context,
          icon: AppIcons.departments,
          label: 'Department',
          value: vm.departmentLabel.trim().isEmpty ? '—' : vm.departmentLabel.trim(),
        ),
      ],
    );
  }

  static Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? const Color(0xFF0F172A) : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
