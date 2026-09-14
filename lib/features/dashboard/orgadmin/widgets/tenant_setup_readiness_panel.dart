import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../services/tenant_setup_readiness_service.dart';
import '../../chrome/dashboard_components.dart';

/// Lightweight setup summary for Hackz orgAdmin — no wizard, no persisted flags.
class TenantSetupReadinessPanel extends StatelessWidget {
  const TenantSetupReadinessPanel({
    super.key,
    required this.readiness,
    this.onRefresh,
  });

  final TenantSetupReadiness readiness;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool ready = readiness.isReady;
    final Color accent = ready ? const Color(0xFF047857) : const Color(0xFFEA580C);
    final String title = ready ? 'Tenant ready for team leaders' : 'Setup incomplete';

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(ready ? AppIcons.workflowApproved : AppIcons.clock, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _planHint(readiness.commercialPlan),
                      style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh readiness',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < readiness.items.length; i++) ...<Widget>[
            _CheckRow(item: readiness.items[i]),
            if (i != readiness.items.length - 1) const SizedBox(height: 8),
          ],
          if (!ready && readiness.incompleteRequired.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              'Next: ${readiness.incompleteRequired.first.label}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Use the sidebar for Manage College, Problem Statements, Events, and Payment Verification.',
            style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  static String _planHint(OrganizationCommercialPlan plan) {
    return switch (plan) {
      OrganizationCommercialPlan.perIdea =>
        'PER_IDEA: team leaders pay per idea; you validate payments before ideas become eligible.',
      OrganizationCommercialPlan.perEvent =>
        'PER_EVENT: no per-idea payment; SysAdmin activates event commercial access on the Control Plane.',
      OrganizationCommercialPlan.annual =>
        'ANNUAL: no per-idea payment; events follow the organisation contract window.',
    };
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});

  final TenantSetupCheckItem item;

  @override
  Widget build(BuildContext context) {
    final bool done = item.done;
    final Color fg = done ? const Color(0xFF047857) : const Color(0xFF64748B);
    final String suffix = item.requiredForReady ? '' : ' (optional)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              done ? AppIcons.workflowApproved : AppIcons.clock,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                done ? '${item.label}$suffix  ✓' : '${item.label}$suffix',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
        if (item.detail != null && !done) ...<Widget>[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              item.detail!,
              style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ],
    );
  }
}
