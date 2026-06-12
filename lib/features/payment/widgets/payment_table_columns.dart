import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_components.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/ui/common/entity_card_pills.dart';
import 'package:hackz/core/ui/data_view/data_table_column.dart';

import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import 'payment_status_pill.dart';

/// Shared amount typography for payment list table and mobile cards.
abstract final class PaymentListStyles {
  PaymentListStyles._();

  static const TextStyle amount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF111827),
  );
}

class PaymentTableActions {
  const PaymentTableActions({
    required this.onOpenDetail,
  });

  final void Function(DepartmentPaymentContribution item) onOpenDetail;
}

abstract final class PaymentTableColumns {
  static List<DataTableColumn<DepartmentPaymentContribution>> build({
    required PaymentTableActions actions,
  }) {
    return <DataTableColumn<DepartmentPaymentContribution>>[
      DataTableColumn<DepartmentPaymentContribution>(
        label: 'Idea',
        flex: 4,
        minWidth: 200,
        cell: (BuildContext context, DepartmentPaymentContribution item) {
          final String ideaId = item.payment.ideaId.trim();
          final Widget pill = ideaId.isEmpty
              ? EntityCardPills.meta(item.ideaTitle, icon: AppIcons.ideas)
              : EntityCardPills.workspace(
                  item.ideaTitle,
                  ContextPillSemantic.idea,
                  () => WorkspaceNavigator.openIdea(context, ideaId),
                  icon: AppIcons.ideas,
                );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pill,
          );
        },
      ),
      DataTableColumn<DepartmentPaymentContribution>(
        label: 'Team',
        flex: 3,
        minWidth: 140,
        cell: (BuildContext context, DepartmentPaymentContribution item) {
          final String teamId = item.payment.teamId.trim();
          final Widget pill = teamId.isEmpty
              ? EntityCardPills.meta(item.teamName, icon: AppIcons.teams)
              : EntityCardPills.workspace(
                  item.teamName,
                  ContextPillSemantic.team,
                  () => WorkspaceNavigator.openTeam(context, teamId),
                  icon: AppIcons.teams,
                );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pill,
          );
        },
      ),
      DataTableColumn<DepartmentPaymentContribution>(
        label: 'Payment date',
        flex: 2,
        minWidth: 148,
        cell: (BuildContext context, DepartmentPaymentContribution item) => Text(
          formatDateTime(item.payment.createdAt),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ),
      DataTableColumn<DepartmentPaymentContribution>(
        label: 'Status',
        flex: 2,
        minWidth: 120,
        cell: (BuildContext context, DepartmentPaymentContribution item) => PaymentStatusPill(
          status: item.payment.status,
          compact: true,
          showAttentionDot: item.needsAttention,
        ),
      ),
      DataTableColumn<DepartmentPaymentContribution>(
        label: 'Amount',
        flex: 2,
        minWidth: 100,
        align: Alignment.centerRight,
        cell: (BuildContext context, DepartmentPaymentContribution item) => Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => actions.onOpenDetail(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                PaymentFinanceHelpers.formatCurrency(item.payment.amount),
                style: PaymentListStyles.amount,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Compact premium card for mobile payments list.
class PaymentListRowCard extends StatelessWidget {
  const PaymentListRowCard({
    super.key,
    required this.item,
    required this.actions,
  });

  final DepartmentPaymentContribution item;
  final PaymentTableActions actions;

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(AppIcons.ideas, size: 20, color: Color(0xFF4A67FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.ideaTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MobileRowCardStyles.title.copyWith(decoration: TextDecoration.none),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => actions.onOpenDetail(item),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 1),
                  child: Text(
                    PaymentFinanceHelpers.formatCurrency(payment.amount),
                    style: PaymentListStyles.amount,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 8),
              PaymentStatusPill(
                status: payment.status,
                compact: true,
                showAttentionDot: item.needsAttention,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatDateTime(payment.createdAt),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
