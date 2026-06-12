import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/workspace/user_workspace_avatar.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

import '../services/payment_finance_helpers.dart';
import 'payment_workspace.dart';
import 'payment_workspace_loader.dart';

class PaymentSummarySection extends StatelessWidget {
  const PaymentSummarySection({super.key, required this.vm});

  final PaymentWorkspaceViewModel vm;

  static const double _iconWidth = 22;
  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final payment = vm.payment;
    final String department =
        vm.departmentLabel.trim().isEmpty ? '—' : vm.departmentLabel.trim();

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
        const SizedBox(height: 12),
        _formRow(
          icon: AppIcons.clock,
          label: 'Payment date',
          value: _plainValue(formatDateTime(payment.createdAt)),
        ),
        _formRow(
          icon: AppIcons.ideas,
          label: 'Idea',
          value: payment.ideaId.trim().isEmpty
              ? _plainValue(vm.ideaTitle)
              : _contextPill(
                  label: vm.ideaTitle,
                  semantic: ContextPillSemantic.idea,
                  onTap: () => PaymentWorkspace.openIdeaFromPayment(context, vm),
                ),
        ),
        _formRow(
          icon: AppIcons.teams,
          label: 'Team',
          value: payment.teamId.trim().isEmpty
              ? _plainValue(vm.teamName)
              : _contextPill(
                  label: vm.teamName,
                  semantic: ContextPillSemantic.team,
                  onTap: () => PaymentWorkspace.openTeamFromPayment(context, vm),
                ),
        ),
        _payerRow(context),
        _formRow(
          icon: AppIcons.departments,
          label: 'Department',
          value: _plainValue(department),
        ),
      ],
    );
  }

  Widget _payerRow(BuildContext context) {
    final payment = vm.payment;
    final String payerId = payment.paidByStudentId.trim();
    final String payerName = vm.payerName.trim().isEmpty ? '—' : vm.payerName.trim();
    final UserModel? payer = vm.payer;
    final UserModel? payerUser = payer != null && payerId.isNotEmpty ? payer : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _iconWidth,
            child: const Icon(AppIcons.student, size: 16, color: Color(0xFF64748B)),
          ),
          SizedBox(
            width: _labelWidth,
            child: const Text(
              'Payer',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (payerUser != null)
                    UserWorkspaceAvatar(
                      user: payerUser,
                      radius: 12,
                      ringPadding: 2,
                      onTap: () => PaymentWorkspace.openUserFromPayment(context, vm),
                    )
                  else
                    _fallbackAvatar(payerName),
                  const SizedBox(width: 8),
                  Expanded(child: _plainValue(payerName)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formRow({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _iconWidth,
            child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
          ),
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _contextPill({
    required String label,
    required ContextPillSemantic semantic,
    required VoidCallback onTap,
  }) {
    final String text = label.trim().isEmpty ? '—' : label.trim();
    return ContextPill(
      label: text,
      semantic: semantic,
      onTap: onTap,
      compact: true,
      fitContent: true,
    );
  }

  static Widget _plainValue(String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
    );
  }

  static Widget _fallbackAvatar(String displayName) {
    final String trimmed = displayName.trim();
    final String initial = trimmed.isEmpty || trimmed == '—' ? '?' : trimmed.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      child: Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
