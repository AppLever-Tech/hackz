import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../chrome/dashboard_components.dart';

class OrgAdminQuickAction {
  const OrgAdminQuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class OrgAdminQuickActionsSection extends StatelessWidget {
  const OrgAdminQuickActionsSection({
    super.key,
    required this.actions,
  });

  final List<OrgAdminQuickAction> actions;

  static List<OrgAdminQuickAction> buildActions({
    required OrganizationCommercialPlan plan,
    required VoidCallback onImportTeams,
    required VoidCallback onImportProblems,
    required VoidCallback onCreateEvent,
    required VoidCallback onReviewPayments,
  }) {
    final List<OrgAdminQuickAction> list = <OrgAdminQuickAction>[
      OrgAdminQuickAction(
        label: 'Import teams',
        subtitle: 'Team registration CSV',
        icon: AppIcons.teams,
        color: const Color(0xFF4A67FF),
        onTap: onImportTeams,
      ),
      OrgAdminQuickAction(
        label: 'Import problems',
        subtitle: 'Problem statements',
        icon: AppIcons.problems,
        color: const Color(0xFF059669),
        onTap: onImportProblems,
      ),
      OrgAdminQuickAction(
        label: 'Create event',
        subtitle: 'Schedule an ideathon',
        icon: AppIcons.event,
        color: const Color(0xFF7C3AED),
        onTap: onCreateEvent,
      ),
    ];
    if (plan == OrganizationCommercialPlan.perIdea) {
      list.add(
        OrgAdminQuickAction(
          label: 'Review payments',
          subtitle: 'PER_IDEA approvals',
          icon: AppIcons.verification,
          color: const Color(0xFFEA580C),
          onTap: onReviewPayments,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardCardTitle(title: 'Quick actions', icon: AppIcons.dashboard),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = ResponsiveHelper.isMobile(context)
                  ? 2
                  : (constraints.maxWidth >= 720 ? 4 : 2);
              final double gap = ResponsiveHelper.metricGridSpacing(context);
              final double tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: actions
                    .map(
                      (OrgAdminQuickAction action) => SizedBox(
                        width: tileWidth,
                        child: _QuickActionTile(action: action),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final OrgAdminQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: action.color.withValues(alpha: 0.22)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                action.color.withValues(alpha: 0.1),
                action.color.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 20, color: action.color),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
