import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../utils/common_helpers.dart';
import '../../../organization/models/organization_model.dart';
import '../../../organization/services/organisation_access.dart';
import '../../../user/models/user_model.dart';
import 'copy_organisation_code_button.dart';

class OrganisationCodeRow extends StatelessWidget {
  const OrganisationCodeRow({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final bool hasCode = code.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.key, size: 16, color: hasCode ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Organisation code',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                ),
                Text(
                  hasCode ? code : 'Assigned at activation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: hasCode ? 0.6 : 0,
                    color: hasCode ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (hasCode) CopyOrganisationCodeButton(code: code),
        ],
      ),
    );
  }
}

class OrganisationAdminRow extends StatelessWidget {
  const OrganisationAdminRow({
    super.key,
    required this.label,
    required this.admin,
    required this.onAdd,
    required this.showAdd,
    required this.icon,
  });

  final String label;
  final UserModel? admin;
  final VoidCallback onAdd;
  final bool showAdd;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final UserModel? user = admin;
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: user == null ? const Color(0xFF94A3B8) : const Color(0xFF334155),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
              ),
              Text(
                user == null ? 'Not assigned' : userDisplayName(user),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: user == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        if (showAdd)
          TextButton(
            onPressed: onAdd,
            child: const Text('Assign'),
          ),
      ],
    );
  }
}

class OrganisationAccessChip extends StatelessWidget {
  const OrganisationAccessChip({super.key, required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color fg = active ? const Color(0xFF047857) : const Color(0xFF64748B);
    final Color bg = active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(active ? AppIcons.workflowApproved : AppIcons.lock, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

class OrganisationMetaChip extends StatelessWidget {
  const OrganisationMetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

String organisationValidityLabel(OrganizationModel organization) {
  if (!organization.commercialPlan.isTimeBound) {
    return organization.commercialPlan.label;
  }
  final DateTime? from = organization.validFrom;
  final DateTime? until = organization.validUntil;
  if (from == null || until == null) return 'Validity not set';
  return '${formatShortDate(from)} – ${formatShortDate(until)}';
}

String organisationCommercialUsabilityLabel(OrganizationModel organization) {
  final bool usable = OrganisationAccess.isGranted(organization);
  return usable ? 'Commercially usable' : 'Not usable';
}
