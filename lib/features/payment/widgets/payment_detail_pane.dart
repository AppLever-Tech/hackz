import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/responsive/responsive_helper.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/ui/dialog/app_dialog_template.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_components.dart';
import 'package:hackz/core/workspace/user_workspace_avatar.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

import '../models/payment_model.dart';
import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import 'payment_form_row.dart';
import 'payment_proof_panel.dart';
import 'payment_status_pill.dart';
import 'team_contribution_section.dart';
import 'verification_timeline_widget.dart';

Future<void> showPaymentDetailDialog(
  BuildContext context, {
  required DepartmentPaymentDetail detail,
}) {
  final bool compact = ResponsiveHelper.isMobile(context);
  return showAppDialog<void>(
    context: context,
    width: compact ? DialogWidthPreset.compact : DialogWidthPreset.wide,
    child: PaymentDetailPane(detail: detail, compact: compact),
  );
}

class PaymentDetailPane extends StatelessWidget {
  const PaymentDetailPane({
    super.key,
    required this.detail,
    this.compact = false,
    this.sectionBorderRadius = 20,
  });

  final DepartmentPaymentDetail detail;
  final bool compact;
  final double sectionBorderRadius;

  @override
  Widget build(BuildContext context) {
    final payment = detail.contribution.payment;
    final contribution = detail.contribution;
    final double amountFontSize = compact ? 22 : 26;
    final double sectionRadius = compact ? 14 : sectionBorderRadius;
    final EdgeInsets sectionPadding = compact ? const EdgeInsets.all(12) : const EdgeInsets.all(14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionPanel(
          borderRadius: sectionRadius,
          padding: sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(AppIcons.payments, color: Color(0xFF0891B2), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ),
                  PaymentStatusPill(status: payment.status, showAttentionDot: contribution.needsAttention),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                PaymentFinanceHelpers.formatCurrency(payment.amount),
                style: TextStyle(fontSize: amountFontSize, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              PaymentFormRow(
                icon: AppIcons.clock,
                label: 'Paid on',
                value: PaymentFormRow.plainValue(formatDateTime(payment.createdAt)),
              ),
              if (payment.verifiedAt != null)
                PaymentFormRow(
                  icon: AppIcons.workflowApproved,
                  label: payment.status == PaymentRecordStatus.rejected ? 'Rejected on' : 'Verified on',
                  value: PaymentFormRow.plainValue(formatDateTime(payment.verifiedAt!)),
                ),
              PaymentFormRow(
                icon: AppIcons.coordinator,
                label: 'Coordinator',
                value: _coordinatorValue(context, detail.coordinator, contribution.coordinatorName),
              ),
              if (payment.transactionId?.trim().isNotEmpty == true)
                PaymentFormRow(
                  icon: AppIcons.payments,
                  label: 'Transaction ID',
                  value: PaymentFormRow.plainValue(payment.transactionId!.trim()),
                  bottomPadding: 0,
                ),
            ],
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _sectionPanel(
          borderRadius: sectionRadius,
          padding: sectionPadding,
          child: TeamContributionSection.fromModels(
            team: detail.team,
            mentor: detail.mentor,
            members: detail.members,
            idea: detail.idea,
            problem: detail.problem,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _sectionPanel(
          borderRadius: sectionRadius,
          padding: sectionPadding,
          child: PaymentProofPanel(
            payment: payment,
            attachments: detail.proofAttachments,
            showDetailHeader: true,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        _sectionPanel(
          borderRadius: sectionRadius,
          padding: sectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(AppIcons.clock, color: Color(0xFF6A38FF), size: 18),
                  SizedBox(width: 8),
                  Text('Verification timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              VerificationTimelineWidget(payment: payment, remarks: payment.remarks),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coordinatorValue(BuildContext context, UserModel? coordinator, String fallbackName) {
    final String name = coordinator != null ? userDisplayName(coordinator) : fallbackName;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (coordinator != null)
          UserWorkspaceAvatar(
            user: coordinator,
            radius: 12,
            ringPadding: 2,
            onTap: () => WorkspaceNavigator.openUser(context, coordinator.userId),
          )
        else
          PaymentFormRow.fallbackAvatar(name, radius: 12),
        const SizedBox(width: 8),
        Expanded(child: PaymentFormRow.plainValue(name)),
      ],
    );
  }

  Widget _sectionPanel({
    required Widget child,
    required double borderRadius,
    required EdgeInsets padding,
  }) {
    return SectionContainer(
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }
}
