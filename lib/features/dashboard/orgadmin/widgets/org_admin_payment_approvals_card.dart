import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../services/org_admin_dashboard_service.dart';
import '../../chrome/dashboard_components.dart';

class OrgAdminPaymentApprovalsCard extends StatelessWidget {
  const OrgAdminPaymentApprovalsCard({
    super.key,
    required this.counts,
    required this.onReviewPayments,
  });

  final OrgAdminPaymentApprovalCounts counts;
  final VoidCallback onReviewPayments;

  @override
  Widget build(BuildContext context) {
    final bool needsAction = counts.pending > 0;
    final Color accent = needsAction ? const Color(0xFFEA580C) : const Color(0xFF047857);

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                needsAction ? AppIcons.clock : AppIcons.workflowApproved,
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Payment approvals',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      needsAction
                          ? '${counts.pending} payment${counts.pending == 1 ? '' : 's'} awaiting your review.'
                          : 'All payments reviewed.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (needsAction)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: const Text(
                    'Action required',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9A3412)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool narrow = constraints.maxWidth < 420;
              final Widget pending = _CountTile(
                label: 'Pending approval',
                value: counts.pending,
                color: const Color(0xFFEA580C),
                emphasized: true,
              );
              final Widget approved = _CountTile(
                label: 'Approved',
                value: counts.verified,
                color: const Color(0xFF047857),
              );
              final Widget rejected = _CountTile(
                label: 'Rejected',
                value: counts.rejected,
                color: const Color(0xFF64748B),
              );
              if (narrow) {
                return Column(
                  children: <Widget>[
                    pending,
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(child: approved),
                        const SizedBox(width: 8),
                        Expanded(child: rejected),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: pending),
                  const SizedBox(width: 8),
                  Expanded(child: approved),
                  const SizedBox(width: 8),
                  Expanded(child: rejected),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onReviewPayments,
              icon: Icon(needsAction ? AppIcons.verification : AppIcons.workflowApproved, size: 18),
              label: Text(needsAction ? 'Review pending' : 'Review payments'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: emphasized ? 0.45 : 0.22), width: emphasized ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: emphasized ? 24 : 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
