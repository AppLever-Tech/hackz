import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../services/tenant_setup_readiness_service.dart';
import 'tenant_setup_readiness_panel.dart';
import '../../chrome/dashboard_components.dart';

/// Compact tenant readiness for orgAdmin dashboard (collapses when ready).
class OrgAdminTenantReadinessCard extends StatefulWidget {
  const OrgAdminTenantReadinessCard({
    super.key,
    required this.readiness,
    this.onRefresh,
    this.onNavigateToModule,
  });

  final TenantSetupReadiness readiness;
  final VoidCallback? onRefresh;
  final ValueChanged<int>? onNavigateToModule;

  static const Set<String> _operationalLabels = <String>{
    'Departments configured',
    'Problem statements available',
    'Teams registered',
    'Event open for team submissions',
  };

  @override
  State<OrgAdminTenantReadinessCard> createState() => _OrgAdminTenantReadinessCardState();
}

class _OrgAdminTenantReadinessCardState extends State<OrgAdminTenantReadinessCard> {
  bool _expanded = false;

  List<TenantSetupCheckItem> get _operationalItems => widget.readiness.items
      .where((TenantSetupCheckItem i) => OrgAdminTenantReadinessCard._operationalLabels.contains(i.label))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final bool ready = widget.readiness.isReady;
    if (ready && !_expanded) {
      return SectionContainer(
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.workflowApproved, color: Color(0xFF047857), size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tenant ready ✓',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = true),
              child: const Text('View setup'),
            ),
            if (widget.onRefresh != null)
              IconButton(
                tooltip: 'Refresh readiness',
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
          ],
        ),
      );
    }

    if (ready && _expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionContainer(
            child: Row(
              children: <Widget>[
                const Icon(AppIcons.workflowApproved, color: Color(0xFF047857), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tenant ready ✓',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _expanded = false),
                  child: const Text('Hide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TenantSetupReadinessPanel(
            readiness: _withItems(widget.readiness, _operationalItems),
            onRefresh: widget.onRefresh,
            onNavigateToModule: widget.onNavigateToModule,
          ),
        ],
      );
    }

    return TenantSetupReadinessPanel(
      readiness: _withItems(widget.readiness, _operationalItems),
      onRefresh: widget.onRefresh,
      onNavigateToModule: widget.onNavigateToModule,
      compactTitle: 'Tenant setup',
    );
  }

  static TenantSetupReadiness _withItems(
    TenantSetupReadiness source,
    List<TenantSetupCheckItem> items,
  ) {
    return TenantSetupReadiness(
      items: items,
      commercialPlan: source.commercialPlan,
      organizationName: source.organizationName,
      counts: source.counts,
      organisationAccessGranted: source.organisationAccessGranted,
    );
  }
}
