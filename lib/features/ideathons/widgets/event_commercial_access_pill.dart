import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../organization/models/enums/organization_commercial_plan.dart';
import '../../organization/services/commercial_access.dart';
import '../models/event_commercial_access.dart';
import '../models/ideathon_model.dart';

/// Compact Department Admin commercial-access indicator. Not a SysAdmin control.
class EventCommercialAccessPill extends StatelessWidget {
  const EventCommercialAccessPill({
    super.key,
    required this.plan,
    this.access = EventCommercialAccess.enabled,
    this.compact = true,
  });

  final OrganizationCommercialPlan plan;
  final EventCommercialAccess access;
  final bool compact;

  static Widget forEvent({
    required IdeathonModel event,
    OrganizationCommercialPlan? plan,
    bool compact = true,
  }) {
    if (plan != null) {
      return EventCommercialAccessPill(
        plan: plan,
        access: event.commercialAccess,
        compact: compact,
      );
    }
    return _AsyncEventCommercialAccessPill(
      orgId: event.orgId,
      access: event.commercialAccess,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String label = CommercialAccess.departmentAdminIndicator(plan: plan, access: access);
    final bool revoked = access.isRevoked;
    final bool pending = !revoked && plan == OrganizationCommercialPlan.perEvent && access.isPending;
    final Color color = revoked
        ? const Color(0xFF64748B)
        : pending
            ? const Color(0xFFB45309)
            : plan == OrganizationCommercialPlan.perIdea
                ? const Color(0xFFB45309)
                : const Color(0xFF047857);
    final Color fill = revoked
        ? const Color(0xFFF1F5F9)
        : pending || plan == OrganizationCommercialPlan.perIdea
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFECFDF5);
    final IconData icon = revoked
        ? AppIcons.lock
        : pending
            ? AppIcons.accountPending
            : plan == OrganizationCommercialPlan.perIdea
                ? AppIcons.payments
                : AppIcons.accountApproved;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _AsyncEventCommercialAccessPill extends StatelessWidget {
  const _AsyncEventCommercialAccessPill({
    required this.orgId,
    required this.access,
    required this.compact,
  });

  final String orgId;
  final EventCommercialAccess access;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrganizationCommercialPlan>(
      future: CommercialAccess.planForOrg(orgId),
      builder: (BuildContext context, AsyncSnapshot<OrganizationCommercialPlan> snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return EventCommercialAccessPill(
          plan: snapshot.data!,
          access: access,
          compact: compact,
        );
      },
    );
  }
}
