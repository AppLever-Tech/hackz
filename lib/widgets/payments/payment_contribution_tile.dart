import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/department_payments_service.dart';
import '../../utils/payment_finance_helpers.dart';
import 'payment_status_pill.dart';

class PaymentContributionTile extends StatelessWidget {
  const PaymentContributionTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DepartmentPaymentContribution item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final payment = item.payment;
    final border = selected ? const Color(0xFF6A38FF) : (item.isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: kDashboardCardDecoration.copyWith(
            border: Border.all(color: border, width: selected ? 1.6 : 1.1),
            color: selected ? const Color(0xFFF8F5FF) : const Color(0xFFFCFDFF),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.ideaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: <Widget>[
                            const Icon(AppIcons.problems, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.problemTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    PaymentFinanceHelpers.formatCurrency(payment.amount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(AppIcons.teams, size: 14, color: Color(0xFF6A38FF)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                  PaymentStatusPill(
                    status: payment.status,
                    compact: true,
                    showAttentionDot: item.needsAttention,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  _metaChip(AppIcons.clock, PaymentFinanceHelpers.formatDate(payment.createdAt)),
                  if (item.isOverdue)
                    _metaChip(AppIcons.statusRejected, 'Overdue', color: const Color(0xFFB91C1C))
                  else if (item.isRecentlyVerified)
                    _metaChip(AppIcons.statusApproved, 'Recently verified', color: const Color(0xFF047857))
                  else if (item.needsAttention)
                    _metaChip(AppIcons.info, 'Needs attention', color: const Color(0xFFB45309)),
                  _metaChip(AppIcons.student, '${item.studentCount} students'),
                  _metaChip(AppIcons.coordinator, item.coordinatorName, maxWidth: 140),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, {Color? color, double? maxWidth}) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF64748B)),
    );
    return Container(
      constraints: maxWidth == null ? null : BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color ?? const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Flexible(child: text),
        ],
      ),
    );
  }
}
