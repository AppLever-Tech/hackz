import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/empty_search_state.dart';
import '../../../utils/common_helpers.dart';
import '../../events/models/event_payment_entry.dart';
import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';
import '../services/payment_proof_launcher.dart';
import 'payment_table_columns.dart';

/// Shared payment list used by Ideathon Payments and Coordinator verification.
class PaymentEntriesView extends StatelessWidget {
  const PaymentEntriesView({
    super.key,
    required this.entries,
    this.ideaColumnLabel = 'Idea',
    this.emptyTitle = 'No payments found',
    this.emptyMessage = 'Try adjusting your search or check back later.',
    this.onClearFilters,
  });

  final List<EventPaymentEntry> entries;
  final String ideaColumnLabel;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? onClearFilters;

  static String statusLabel(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 'Confirmed',
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.rejected => 'Exception',
    };
  }

  static String amountLabel(EventPaymentEntry row) {
    if (row.payment == null) return '—';
    return PaymentFinanceHelpers.formatCurrency(row.payment!.amount);
  }

  static String dateLabel(EventPaymentEntry row) {
    final DateTime? at = row.payment?.createdAt;
    if (at == null) return '—';
    return formatDateTime(at);
  }

  static void openIdea(BuildContext context, EventPaymentEntry row) {
    if (row.entryId.trim().isEmpty) return;
    WorkspaceNavigator.openIdea(context, row.entryId);
  }

  static void openTeam(BuildContext context, EventPaymentEntry row) {
    if (row.teamId.trim().isEmpty) return;
    WorkspaceNavigator.openTeam(context, row.teamId);
  }

  static void openPayment(BuildContext context, EventPaymentEntry row) {
    final String? id = row.paymentId;
    if (id == null) {
      openIdea(context, row);
      return;
    }
    WorkspaceNavigator.openPayment(context, id);
  }

  static Future<void> openProof(BuildContext context, EventPaymentEntry row) async {
    final PaymentModel? payment = row.payment;
    if (payment == null) return;
    await PaymentProofLauncher.open(context, payment);
  }

  static Widget ideaPill(BuildContext context, EventPaymentEntry row) {
    final String label = row.entryTitle.trim().isEmpty ? row.entryId : row.entryTitle;
    if (row.entryId.trim().isEmpty) {
      return EntityCardPills.meta(label, icon: AppIcons.ideas);
    }
    return EntityCardPills.workspace(
      label,
      ContextPillSemantic.idea,
      () => openIdea(context, row),
      icon: AppIcons.ideas,
    );
  }

  static Widget teamPill(BuildContext context, EventPaymentEntry row) {
    final String label = row.teamName.trim().isEmpty ? '—' : row.teamName;
    if (row.teamId.trim().isEmpty) {
      return EntityCardPills.meta(label, icon: AppIcons.teams);
    }
    return EntityCardPills.workspace(
      label,
      ContextPillSemantic.team,
      () => openTeam(context, row),
      icon: AppIcons.teams,
    );
  }

  static Widget statusPill(BuildContext context, EventPaymentEntry row) {
    return ContextPill(
      label: statusLabel(row.status),
      semantic: ContextPillSemantic.payment,
      onTap: () => openPayment(context, row),
      enabled: row.paymentId != null,
      compact: true,
      fitContent: true,
      expandWidth: false,
      allowHoverScale: false,
    );
  }

  static Widget proofIcon(BuildContext context, EventPaymentEntry row) {
    if (!row.hasProof || row.payment == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Payment screenshot',
      onPressed: () => openProof(context, row),
      icon: const Icon(AppIcons.attachments, size: 16, color: Color(0xFF475569)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  static Widget statusWithProof(BuildContext context, EventPaymentEntry row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        statusPill(context, row),
        if (row.hasProof && row.payment != null) proofIcon(context, row),
      ],
    );
  }

  static Widget pillCell(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: UnconstrainedBox(
        alignment: Alignment.centerLeft,
        constrainedAxis: Axis.vertical,
        child: child,
      ),
    );
  }

  static List<DataTableColumn<EventPaymentEntry>> columns({required String ideaColumnLabel}) {
    return <DataTableColumn<EventPaymentEntry>>[
      DataTableColumn<EventPaymentEntry>(
        label: ideaColumnLabel,
        flex: 4,
        minWidth: 180,
        gapAfter: 12,
        cell: (BuildContext context, EventPaymentEntry row) => pillCell(ideaPill(context, row)),
      ),
      DataTableColumn<EventPaymentEntry>(
        label: 'Team',
        flex: 3,
        minWidth: 140,
        gapAfter: 12,
        cell: (BuildContext context, EventPaymentEntry row) => pillCell(teamPill(context, row)),
      ),
      DataTableColumn<EventPaymentEntry>(
        label: 'Payment Date',
        flex: 2,
        minWidth: 148,
        gapAfter: 12,
        cell: (_, EventPaymentEntry row) => Text(
          dateLabel(row),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ),
      DataTableColumn<EventPaymentEntry>(
        label: 'Status',
        flex: 2,
        minWidth: 148,
        gapAfter: 12,
        cell: (BuildContext context, EventPaymentEntry row) => pillCell(statusWithProof(context, row)),
      ),
      DataTableColumn<EventPaymentEntry>(
        label: 'Amount',
        flex: 2,
        minWidth: 100,
        align: Alignment.centerRight,
        cell: (_, EventPaymentEntry row) => Align(
          alignment: Alignment.centerRight,
          child: Text(amountLabel(row), style: PaymentListStyles.amount),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptySearchState.payments(
        title: emptyTitle,
        message: emptyMessage,
        onClearSearch: onClearFilters,
      );
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    if (mobile) return _cards(context);
    return DataTableView<EventPaymentEntry>(
      items: entries,
      rowMinHeight: 56,
      columns: columns(ideaColumnLabel: ideaColumnLabel),
    );
  }

  Widget _cards(BuildContext context) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final EventPaymentEntry row = entries[i];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: kDashboardCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: ideaPill(context, row)),
                  const SizedBox(width: 8),
                  Text(amountLabel(row), style: PaymentListStyles.amount),
                ],
              ),
              const SizedBox(height: 8),
              teamPill(context, row),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      dateLabel(row),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ),
                  statusWithProof(context, row),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
