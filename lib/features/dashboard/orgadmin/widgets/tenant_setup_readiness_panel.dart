import 'package:flutter/gestures.dart';
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
    this.onNavigateToModule,
  });

  final TenantSetupReadiness readiness;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onNavigateToModule;

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
            _CheckRow(
              item: readiness.items[i],
              onNavigateToModule: onNavigateToModule,
            ),
            if (i != readiness.items.length - 1) const SizedBox(height: 8),
          ],
          if (!ready && readiness.incompleteRequired.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _NextStepRow(
              item: readiness.incompleteRequired.first,
              onNavigateToModule: onNavigateToModule,
            ),
          ],
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

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.item,
    this.onNavigateToModule,
  });

  final TenantSetupCheckItem item;
  final ValueChanged<int>? onNavigateToModule;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.play_arrow_rounded, size: 18, color: Colors.orange.shade800),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
                  children: <InlineSpan>[
                    const TextSpan(
                      text: 'Next: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: item.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              if (item.detail != null && !item.done)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _DetailWithModuleLink(
                    detail: item.detail!,
                    navAction: item.navAction,
                    onNavigateToModule: onNavigateToModule,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.item,
    this.onNavigateToModule,
  });

  final TenantSetupCheckItem item;
  final ValueChanged<int>? onNavigateToModule;

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
            child: _DetailWithModuleLink(
              detail: item.detail!,
              navAction: item.navAction,
              onNavigateToModule: onNavigateToModule,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailWithModuleLink extends StatelessWidget {
  const _DetailWithModuleLink({
    required this.detail,
    this.navAction,
    this.onNavigateToModule,
  });

  final String detail;
  final TenantSetupNavAction? navAction;
  final ValueChanged<int>? onNavigateToModule;

  static const TextStyle _detailStyle = TextStyle(
    fontSize: 11,
    height: 1.35,
    color: Color(0xFF94A3B8),
  );

  static const TextStyle _linkStyle = TextStyle(
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: Color(0xFF4338CA),
    decoration: TextDecoration.underline,
  );

  @override
  Widget build(BuildContext context) {
    final TenantSetupNavAction? action = navAction;
    if (action == null || onNavigateToModule == null) {
      return Text(detail, style: _detailStyle);
    }

    final String label = action.label.trim();
    final String trimmedDetail = detail.trimRight();
    final String paren = '($label)';
    if (trimmedDetail.endsWith(paren)) {
      final String prefix = trimmedDetail.substring(0, trimmedDetail.length - paren.length).trimRight();
      final String beforeParen = prefix.endsWith('(') ? prefix : '$prefix ';
      return RichText(
        text: TextSpan(
          style: _detailStyle,
          children: <InlineSpan>[
            TextSpan(text: beforeParen),
            TextSpan(
              text: label,
              style: _linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => onNavigateToModule!(action.menuIndex),
            ),
            const TextSpan(text: ').'),
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: _detailStyle,
        children: <InlineSpan>[
          TextSpan(text: trimmedDetail.endsWith('.') ? trimmedDetail : '$trimmedDetail.'),
          const TextSpan(text: ' ('),
          TextSpan(
            text: label,
            style: _linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => onNavigateToModule!(action.menuIndex),
          ),
          const TextSpan(text: ').'),
        ],
      ),
    );
  }
}
