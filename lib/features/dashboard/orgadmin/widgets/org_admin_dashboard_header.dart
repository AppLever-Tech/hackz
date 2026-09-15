import 'package:flutter/material.dart';

import '../../../../core/ui/common/page_header_context_pill.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../chrome/dashboard_components.dart';

class OrgAdminDashboardHeader extends StatelessWidget {
  const OrgAdminDashboardHeader({
    super.key,
    required this.displayName,
    required this.organisationName,
    required this.commercialPlan,
    required this.organisationAccessGranted,
  });

  final String displayName;
  final String organisationName;
  final OrganizationCommercialPlan commercialPlan;
  final bool organisationAccessGranted;

  static String greetingFor(DateTime now) {
    final int hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final String greeting = greetingFor(DateTime.now());
    final String org = organisationName.trim();
    final String accessLabel = organisationAccessGranted ? 'Active' : 'Inactive';

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$greeting, $displayName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Organisation Admin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          if (org.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                PageHeaderContextPill.fromItem(PageHeaderContextItem.organization(org)),
                _PlanStatusPill(
                  label: '${commercialPlan.wireValue} • $accessLabel',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanStatusPill extends StatelessWidget {
  const _PlanStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
