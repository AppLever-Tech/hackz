import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../models/enums/organization_type.dart';
import '../../../models/organization_model.dart';
import '../../user/models/user_model.dart';
import '../../user/screens/create_user_dialog.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../screens/sysadmin/organization_dialog.dart';
import '../../../shared/common/external_url_icon.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../../workspace/core/workspace_navigator.dart';
import '../../../widgets/common/context_pill.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../models/org_operational_data.dart';
import 'org_metadata_row.dart';

/// Full-width operational organization card.
class OrganizationManagementCard extends StatelessWidget {
  const OrganizationManagementCard({
    super.key,
    required this.organization,
    required this.operationalData,
    required this.onChanged,
  });

  final OrganizationModel organization;
  final OrgOperationalData operationalData;
  final VoidCallback onChanged;

  Future<void> _removeCollegeAdmin(BuildContext context, UserModel admin) async {
    final adminId = admin.userId.trim();
    if (adminId.isEmpty) return;
    final name = userDisplayName(admin);
    final ok = await FeedbackService.showConfirmation(
      context,
      title: 'Remove college admin?',
      message: 'Remove $name from ${organization.name}?',
      confirmLabel: 'Remove',
      dangerConfirm: true,
    );
    if (!ok) return;
    await FirestoreUtils.deleteUser(adminId);
    if (context.mounted) {
      FeedbackService.showSuccess(
        context,
        title: 'Admin removed',
        message: '$name was removed',
      );
      onChanged();
    }
  }

  Future<void> _assignCollegeAdmin(BuildContext context) async {
    final assigned = await showCreateUserDialog(
      context: context,
      roleCode: 'CADM',
      organization: organization,
    );
    if (assigned) onChanged();
  }

  Future<void> _deleteOrganization(BuildContext context) async {
    final ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete organization?',
      message: 'This will permanently remove "${organization.name}".',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return;
    try {
      await FirestoreUtils.deleteOrganization(organization.id);
      if (context.mounted) {
        FeedbackService.showSuccess(
          context,
          title: 'Deleted',
          message: '${organization.name} was removed',
        );
        onChanged();
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackService.showError(
          context,
          title: 'Delete failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _editOrganization(BuildContext context) async {
    final saved = await showOrganizationDialog(
      context: context,
      initialOrganization: organization,
    );
    if (saved) onChanged();
  }

  List<Widget> _metadataRows(BuildContext context) {
    final type = organization.type;
    return <Widget>[
      OrgMetadataRow(
        icon: AppIcons.address,
        label: 'Address',
        value: organization.address,
        maxValueLines: 3,
      ),
      OrgMetadataRow(
        icon: AppIcons.phone,
        label: 'Contact Phone',
        value: organization.contact,
      ),
      OrgMetadataRow(
        icon: AppIcons.website,
        label: 'Website',
        value: organization.website.trim().isEmpty ? '' : organization.website,
        trailing: organization.website.trim().isEmpty
            ? null
            : ExternalUrlIcon(
                url: organization.website,
                tooltip: 'Open website externally',
                onLaunchFailed: () {
                  FeedbackService.showWarning(
                    context,
                    title: 'Invalid website',
                    message: 'Unable to open website URL.',
                  );
                },
              ),
      ),
      OrgMetadataRow(
        icon: AppIcons.departments,
        label: 'Departments',
        value: '${operationalData.departmentCount}',
      ),
      OrgMetadataRow(
        icon: AppIcons.orgType,
        label: 'Type',
        value: type.displayName,
      ),
      OrgMetadataRow(
        icon: AppIcons.timelineRegistration,
        label: 'Created',
        value: formatDayMonthYear(organization.createdAt),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final type = organization.type;
    final isCollege = type == OrganizationType.college;
    final admin = operationalData.collegeAdmin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECF8)),
                ),
                child: Icon(
                  AppIcons.forOrganizationType(type),
                  size: 22,
                  color: const Color(0xFF6A38FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  organization.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Tooltip(
                message: 'Edit organization',
                child: InkWell(
                  onTap: () => _editOrganization(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(AppIcons.edit, size: 18, color: Color(0xFF6A38FF)),
                  ),
                ),
              ),
              Tooltip(
                message: 'Delete organization',
                child: InkWell(
                  onTap: () => _deleteOrganization(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(AppIcons.remove, size: 18, color: Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
          if (isCollege) ...<Widget>[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE8ECF8)),
            const SizedBox(height: 8),
            _CollegeAdminSection(
              admin: admin,
              onAssign: () => _assignCollegeAdmin(context),
              onRemove: admin == null ? null : () => _removeCollegeAdmin(context, admin),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE8ECF8)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final rows = _metadataRows(context);
              final columnCount = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              if (columnCount == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                );
              }
              final itemWidth = (constraints.maxWidth - (columnCount - 1) * 20) / columnCount;
              return Wrap(
                spacing: 20,
                runSpacing: 4,
                children: rows
                    .map(
                      (Widget row) => SizedBox(
                        width: itemWidth,
                        child: row,
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

class _CollegeAdminSection extends StatelessWidget {
  const _CollegeAdminSection({
    required this.admin,
    required this.onAssign,
    this.onRemove,
  });

  final UserModel? admin;
  final VoidCallback onAssign;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Text(
          'College Admin',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: admin != null
              ? _AssignedAdminRow(
                  admin: admin!,
                  onRemove: onRemove,
                )
              : _AssignAdminPrompt(onAssign: onAssign),
        ),
      ],
    );
  }
}

class _AssignedAdminRow extends StatelessWidget {
  const _AssignedAdminRow({
    required this.admin,
    this.onRemove,
  });

  final UserModel admin;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = userDisplayName(admin);
    final userId = admin.userId.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: ContextPill(
            label: name,
            semantic: ContextPillSemantic.user,
            icon: AppIcons.adminProfile,
            compact: true,
            onTap: userId.isNotEmpty ? () => WorkspaceNavigator.openUser(context, userId) : () {},
            enabled: userId.isNotEmpty,
          ),
        ),
        if (onRemove != null)
          const SizedBox(width: 8),
        if (onRemove != null)
          Tooltip(
            message: 'Remove college admin',
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(AppIcons.remove, size: 15, color: Color(0xFFDC2626)),
              ),
            ),
          ),
      ],
    );
  }
}

class _AssignAdminPrompt extends StatelessWidget {
  const _AssignAdminPrompt({required this.onAssign});

  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'No college admin assigned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onAssign,
          icon: const Icon(AppIcons.add, size: 15),
          label: const Text('Assign'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: const Color(0xFF6A38FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
