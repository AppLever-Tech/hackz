import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/firebase/tenant_registry.dart';
import '../../../core/theme/app_icons.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/widgets/organization_thumbnail.dart';
import '../../user/models/user_model.dart';
import '../../user/screens/create_user_dialog.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/sysadmin/screens/organization_dialog.dart';
import '../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../core/ui/common/external_url_icon.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../models/org_operational_data.dart';
import 'org_metadata_row.dart';

/// Full-width operational organization card.
class OrganizationManagementCard extends StatelessWidget {
  const OrganizationManagementCard({
    super.key,
    required this.organization,
    required this.operationalData,
    required this.onChanged,
    this.organisationCode,
  });

  final OrganizationModel organization;
  final OrgOperationalData operationalData;
  final VoidCallback onChanged;

  /// Control Plane routing code. Not stored on [OrganizationModel].
  final String? organisationCode;

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

  Future<void> _editCollegeAdmin(BuildContext context, UserModel admin) async {
    final changed = await showCreateUserDialog(
      context: context,
      roleCode: 'CADM',
      organization: organization,
      initialUser: admin,
    );
    if (changed) onChanged();
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
      await TenantRegistry.inactivateByOrganisationName(organization.name);
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
    final String code = (organisationCode ?? '').trim();
    return <Widget>[
      if (code.isNotEmpty)
        OrgMetadataRow(
          icon: AppIcons.key,
          label: 'Organisation code',
          value: code,
          trailing: _CopyOrganisationCodeButton(code: code),
        ),
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
      decoration: kDashboardCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DashboardCardTitleBand(
            title: organization.name,
            leading: OrganizationThumbnail(organization: organization, size: 32),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                HoverIconActionButton(
                  icon: AppIcons.edit,
                  tooltip: 'Edit organization',
                  iconSize: 17,
                  onTap: () => _editOrganization(context),
                ),
                HoverIconActionButton(
                  icon: AppIcons.delete,
                  tooltip: 'Delete organization',
                  destructive: true,
                  iconSize: 17,
                  onTap: () => _deleteOrganization(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (isCollege) ...<Widget>[
                  _CollegeAdminRow(
                    admin: admin,
                    onAdd: () => _assignCollegeAdmin(context),
                    onEdit: admin == null ? null : () => _editCollegeAdmin(context, admin),
                    onRemove: admin == null ? null : () => _removeCollegeAdmin(context, admin),
                  ),
                  const SizedBox(height: 14),
                ],
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
          ),
        ],
      ),
    );
  }
}

class _CollegeAdminRow extends StatelessWidget {
  const _CollegeAdminRow({
    required this.admin,
    required this.onAdd,
    this.onEdit,
    this.onRemove,
  });

  final UserModel? admin;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final UserModel? assigned = admin;
    final String name = assigned == null ? '' : userDisplayName(assigned);
    final String userId = assigned?.userId.trim() ?? '';
    final bool hasAdmin = assigned != null && name.isNotEmpty && name != '-';

    return Row(
      children: <Widget>[
        const Text(
          'College admin',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
            height: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        if (hasAdmin) ...<Widget>[
          UserWorkspaceAvatar(
            user: assigned,
            radius: 12,
            ringPadding: 2,
            onTap: userId.isEmpty ? () {} : () => WorkspaceNavigator.openUser(context, userId),
            enabled: userId.isNotEmpty,
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 2),
          if (onEdit != null)
            HoverIconActionButton(
              icon: AppIcons.edit,
              tooltip: 'Edit college admin',
              onTap: onEdit!,
            ),
          if (onRemove != null)
            HoverIconActionButton(
              icon: AppIcons.delete,
              tooltip: 'Remove college admin',
              destructive: true,
              onTap: onRemove!,
            ),
        ] else
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(AppIcons.add, size: 15),
            label: const Text('Add'),
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

class _CopyOrganisationCodeButton extends StatefulWidget {
  const _CopyOrganisationCodeButton({required this.code});

  final String code;

  @override
  State<_CopyOrganisationCodeButton> createState() => _CopyOrganisationCodeButtonState();
}

class _CopyOrganisationCodeButtonState extends State<_CopyOrganisationCodeButton> {
  static const Duration _copiedDuration = Duration(seconds: 2);

  bool _copied = false;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    _revertTimer?.cancel();
    setState(() => _copied = true);
    _revertTimer = Timer(_copiedDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return HoverIconActionButton(
      icon: _copied ? AppIcons.copied : AppIcons.copy,
      tooltip: _copied ? 'Copied' : 'Copy organisation code',
      iconColor: _copied ? const Color(0xFF047857) : null,
      onTap: _copy,
    );
  }
}
