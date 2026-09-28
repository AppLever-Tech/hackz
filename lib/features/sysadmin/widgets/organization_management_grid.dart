import 'package:flutter/material.dart';

import '../../organization/models/organization_model.dart';
import '../models/org_operational_data.dart';
import 'organization_management_card.dart';

/// Full-width list of operational organization cards.
class OrganizationManagementGrid extends StatelessWidget {
  const OrganizationManagementGrid({
    super.key,
    required this.organizations,
    required this.operationalByOrgId,
    required this.onOrganizationChanged,
    this.organisationCodeByName = const <String, String>{},
  });

  final List<OrganizationModel> organizations;
  final Map<String, OrgOperationalData> operationalByOrgId;
  final VoidCallback onOrganizationChanged;
  final Map<String, String> organisationCodeByName;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return Text(
        'No organizations match this filter.',
        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: organizations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final org = organizations[index];
        final data = operationalByOrgId[org.id] ?? const OrgOperationalData();
        return OrganizationManagementCard(
          key: ValueKey<String>(org.id),
          organization: org,
          operationalData: data,
          organisationCode: organisationCodeByName[org.name],
          onChanged: onOrganizationChanged,
        );
      },
    );
  }
}
