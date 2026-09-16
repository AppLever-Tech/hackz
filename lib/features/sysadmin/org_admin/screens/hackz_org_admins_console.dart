import 'package:flutter/material.dart';

import '../../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../../core/responsive/responsive_filter_bar.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/common/card_overflow_menu.dart';
import '../../../../core/ui/common/context_pill_metrics.dart';
import '../../../../core/ui/common/context_pill_theme.dart';
import '../../../../core/ui/common/entity_card_pills.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/workspace/context_launch_surface.dart';
import '../../../../core/workspace/user_workspace_avatar.dart';
import '../../../../core/workspace/workspace_navigator.dart';
import '../../../../core/ui/filters/hackz_filter_pane.dart';
import '../../../../core/ui/inputs/email_field.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/inputs/phone_number_field.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../organization/models/enums/organization_type.dart';
import '../../../organization/models/organization_model.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/enums/user_status.dart';
import '../../../user/models/user_model.dart';
import '../../../user/widgets/user_form_section.dart';
import '../models/hkz_org_admin.dart';
import '../services/hkz_org_admin_service.dart';

enum _OrgAdminStatusFilter { all, active, inactive }

class HackzOrgAdminsConsole extends StatefulWidget {
  const HackzOrgAdminsConsole({super.key});

  @override
  State<HackzOrgAdminsConsole> createState() => _HackzOrgAdminsConsoleState();
}

class _HackzOrgAdminsConsoleState extends State<HackzOrgAdminsConsole> {
  List<HkzOrgAdmin> _admins = const <HkzOrgAdmin>[];
  Map<String, String> _orgNames = const <String, String>{};
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  _OrgAdminStatusFilter _statusFilter = _OrgAdminStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        HkzOrgAdminService.list(),
        FirestoreUtils.getOrganizations(database: HackzFirebase.controlPlane.firestore),
      ]);
      if (!mounted) return;
      final List<OrganizationModel> orgs = results[1] as List<OrganizationModel>;
      setState(() {
        _admins = results[0] as List<HkzOrgAdmin>;
        _orgNames = <String, String>{
          for (final OrganizationModel org in orgs) org.id: org.name,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<HkzOrgAdmin> get _filteredAdmins {
    final String query = _searchController.text.trim().toLowerCase();
    return _admins.where((HkzOrgAdmin admin) {
      if (_statusFilter == _OrgAdminStatusFilter.active && !admin.isActive) return false;
      if (_statusFilter == _OrgAdminStatusFilter.inactive && admin.isActive) return false;
      if (query.isEmpty) return true;
      final String orgBlob = admin.assignedOrganisationIds.map(_orgLabel).join(' ').toLowerCase();
      return admin.displayName.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query) ||
          admin.phone.toLowerCase().contains(query) ||
          orgBlob.contains(query);
    }).toList(growable: false);
  }

  int get _activeCount => _admins.where((HkzOrgAdmin a) => a.isActive).length;

  int get _inactiveCount => _admins.length - _activeCount;

  Future<void> _add() async {
    final bool? saved = await showHackzOrgAdminEditorDialog(context: context, orgNames: _orgNames);
    if (saved == true && mounted) _reload();
  }

  Future<void> _toggleActive(HkzOrgAdmin admin) async {
    try {
      await HkzOrgAdminService.setActive(orgAdminId: admin.id, isActive: !admin.isActive);
      if (mounted) {
        FeedbackService.showSuccess(
          context,
          title: admin.isActive ? 'Deactivated' : 'Activated',
          message: admin.displayName,
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Update failed', message: '$e');
      }
    }
  }

  Future<void> _delete(HkzOrgAdmin admin) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete Hackz org admin?',
      message: 'Permanently remove ${admin.displayName}? Tenant access for assigned organisations will be revoked.',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return;
    try {
      await HkzOrgAdminService.delete(orgAdminId: admin.id);
      if (mounted) {
        FeedbackService.showSuccess(context, title: 'Deleted', message: admin.displayName);
        _reload();
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, title: 'Delete failed', message: '$e');
      }
    }
  }

  Future<void> _manageAssignments(HkzOrgAdmin admin) async {
    final bool? saved = await showHackzOrgAdminAssignmentsDialog(
      context: context,
      admin: admin,
      orgNames: _orgNames,
    );
    if (saved == true && mounted) _reload();
  }

  void _onActionSelected(HkzOrgAdmin admin, String action) {
    switch (action) {
      case 'assign':
        _manageAssignments(admin);
      case 'toggle':
        _toggleActive(admin);
      case 'delete':
        _delete(admin);
    }
  }

  String _orgLabel(String orgId) {
    final String name = (_orgNames[orgId] ?? '').trim();
    if (name.isEmpty) return orgId;
    return name;
  }

  UserModel _userModelForAdmin(HkzOrgAdmin admin) {
    return UserModel(
      userId: admin.id,
      phone: admin.phone,
      firstName: admin.firstName,
      lastName: admin.lastName,
      email: admin.email,
      role: UserRole.orgAdmin.code,
      orgType: OrganizationType.college,
      orgId: admin.assignedOrganisationIds.isNotEmpty ? admin.assignedOrganisationIds.first : '',
      department: '',
      departmentCode: '',
      status: admin.isActive ? UserStatus.active : UserStatus.suspended,
      createdAt: admin.createdAt,
    );
  }

  Future<void> _openAdminUserWorkspace(HkzOrgAdmin admin) async {
    final UserModel? linked = await FirestoreUtils.fetchUserByPhone(
      admin.phone,
      database: HackzFirebase.controlPlane.firestore,
    );
    if (!mounted) return;
    if (linked != null) {
      WorkspaceNavigator.openUser(context, linked.userId);
      return;
    }
    FeedbackService.showInfo(
      context,
      title: 'Profile not linked',
      message:
          'No Control Plane user profile exists for this phone yet. Assign organisations or complete tenant provisioning first.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: HkzProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Unable to load Hackz org admins: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<HkzOrgAdmin> visible = _filteredAdmins;
    final Widget toolbar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search by name, email, phone, or organisation',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      filterLabel: _showFilters ? 'Hide Filters' : 'Show Filters',
      iconOnlyFilterOnMobile: !mobile,
      leading: <Widget>[
        MobileToolbarButtonStyles.filledIcon(
          onPressed: _add,
          label: mobile ? 'Add' : 'Add Hackz org admin',
        ),
      ],
      searchDecoration: HackzInputDecoration.decorate(
        hintText: 'Search by name, email, phone, or organisation',
        compact: true,
        prefixIcon: const Icon(AppIcons.search, size: 18),
      ),
      searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Hackz Organisation Admins',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hackz support users authorised to operate in assigned organisation tenants. '
            'This is not a college employee role.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 14),
          toolbar,
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: HackzFilterPane(
                onClearAll: () => setState(() => _statusFilter = _OrgAdminStatusFilter.all),
                sections: <Widget>[
                  HackzFilterSection.chips(
                    icon: AppIcons.users,
                    label: 'Status',
                    chips: <Widget>[
                      HackzFilterChips.choice(
                        icon: AppIcons.users,
                        label: 'All (${_admins.length})',
                        selected: _statusFilter == _OrgAdminStatusFilter.all,
                        onSelected: () => setState(() => _statusFilter = _OrgAdminStatusFilter.all),
                      ),
                      HackzFilterChips.choice(
                        icon: AppIcons.workflowApproved,
                        label: 'Active ($_activeCount)',
                        selected: _statusFilter == _OrgAdminStatusFilter.active,
                        onSelected: () => setState(() => _statusFilter = _OrgAdminStatusFilter.active),
                      ),
                      HackzFilterChips.choice(
                        icon: AppIcons.clock,
                        label: 'Inactive ($_inactiveCount)',
                        selected: _statusFilter == _OrgAdminStatusFilter.inactive,
                        onSelected: () => setState(() => _statusFilter = _OrgAdminStatusFilter.inactive),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            _empty(hasQuery: _searchController.text.trim().isNotEmpty || _statusFilter != _OrgAdminStatusFilter.all)
          else if (mobile)
            ...visible.map(
              (HkzOrgAdmin admin) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _adminCard(admin),
              ),
            )
          else
            _table(visible),
        ],
      ),
    );
  }

  Widget _empty({required bool hasQuery}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        hasQuery
            ? 'No Hackz org admins match your search or filters.'
            : 'No Hackz org admins yet. Add a support user and assign organisations.',
        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _supportUserCell(HkzOrgAdmin admin) {
    final UserModel user = _userModelForAdmin(admin);
    return Row(
      children: <Widget>[
        Icon(
          AppIcons.helpSupport,
          size: 18,
          color: admin.isActive ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        UserWorkspaceAvatar(
          user: user,
          radius: 16,
          ringPadding: 2,
          onTap: () => _openAdminUserWorkspace(admin),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            admin.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _organisationPills(HkzOrgAdmin admin) {
    if (admin.assignedOrganisationIds.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: admin.assignedOrganisationIds
          .map(
            (String orgId) => EntityCardPills.workspace(
              _orgLabel(orgId),
              ContextPillSemantic.generic,
              () => _manageAssignments(admin),
              icon: AppIcons.organizations,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _statusContextPill(bool active) {
    final Color foreground = active ? const Color(0xFF047857) : const Color(0xFF64748B);
    final Color surface = active ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    final Color border = active ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0);
    final String label = active ? 'Active' : 'Inactive';
    final IconData icon = active ? AppIcons.workflowApproved : AppIcons.clock;
    final BorderRadius radius = ContextPillMetrics.resolvedBorderRadius(compact: true);

    return ContextLaunchSurface(
      enabled: false,
      onTap: () {},
      semantic: ContextPillSemantic.generic,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: Container(
        height: ContextPillMetrics.workspaceHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(HkzOrgAdmin admin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _supportUserCell(admin)),
              _statusContextPill(admin.isActive),
              const SizedBox(width: 8),
              _actionsMenu(admin),
            ],
          ),
          const SizedBox(height: 10),
          Text(admin.phone, style: const TextStyle(fontSize: 13)),
          Text(admin.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          _organisationPills(admin),
        ],
      ),
    );
  }

  Widget _table(List<HkzOrgAdmin> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('Support user', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(flex: 3, child: Text('Organisations', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            _tableRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _tableRow(HkzOrgAdmin admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(flex: 3, child: _supportUserCell(admin)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(admin.phone, style: const TextStyle(fontSize: 13)),
                Text(admin.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(flex: 3, child: _organisationPills(admin)),
          Expanded(
            flex: 2,
            child: Center(child: _statusContextPill(admin.isActive)),
          ),
          SizedBox(
            width: 72,
            child: Center(child: _actionsMenu(admin)),
          ),
        ],
      ),
    );
  }

  Widget _actionsMenu(HkzOrgAdmin admin) {
    return CardOverflowMenuButton(
      tooltip: 'Actions',
      dividersBefore: const <String>{'delete'},
      actions: <CardOverflowMenuAction>[
        CardOverflowMenuAction(
          value: 'assign',
          icon: AppIcons.departments,
          label: 'Organisations',
        ),
        CardOverflowMenuAction(
          value: 'toggle',
          icon: admin.isActive ? AppIcons.workflowRejected : AppIcons.workflowApproved,
          label: admin.isActive ? 'Deactivate' : 'Activate',
        ),
        CardOverflowMenuAction(
          value: 'delete',
          icon: AppIcons.delete,
          label: 'Delete',
          danger: true,
        ),
      ],
      onSelected: (String value) => _onActionSelected(admin, value),
    );
  }

}

Future<bool?> showHackzOrgAdminEditorDialog({
  required BuildContext context,
  required Map<String, String> orgNames,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext _) => _HackzOrgAdminEditorDialog(orgNames: orgNames),
  );
}

class _HackzOrgAdminEditorDialog extends StatefulWidget {
  const _HackzOrgAdminEditorDialog({required this.orgNames});

  final Map<String, String> orgNames;

  @override
  State<_HackzOrgAdminEditorDialog> createState() => _HackzOrgAdminEditorDialogState();
}

class _HackzOrgAdminEditorDialogState extends State<_HackzOrgAdminEditorDialog> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await HkzOrgAdminService.create(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: _email.text,
        phone: normalizePhoneE164(_phone.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) FeedbackService.showError(context, title: 'Create failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Hackz Organisation Admin'),
      content: SizedBox(
        width: 420,
        child: UserFormSection(
          title: 'Support user',
          subtitle: 'Hackz operations identity — not a college employee',
          child: Column(
            children: <Widget>[
              TextField(
                controller: _firstName,
                decoration: HackzInputDecoration.decorate(hintText: 'First name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastName,
                decoration: HackzInputDecoration.decorate(hintText: 'Last name'),
              ),
              const SizedBox(height: 8),
              EmailField(
                controller: _email,
                decoration: HackzInputDecoration.decorate(hintText: 'Email'),
              ),
              const SizedBox(height: 8),
              PhoneNumberField(
                controller: _phone,
                decoration: HackzInputDecoration.decorate(hintText: 'Mobile'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? const HkzProgressIndicator(size: 18) : const Text('Create')),
      ],
    );
  }
}

Future<bool?> showHackzOrgAdminAssignmentsDialog({
  required BuildContext context,
  required HkzOrgAdmin admin,
  required Map<String, String> orgNames,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext _) => _HackzOrgAdminAssignmentsDialog(admin: admin, orgNames: orgNames),
  );
}

class _HackzOrgAdminAssignmentsDialog extends StatefulWidget {
  const _HackzOrgAdminAssignmentsDialog({required this.admin, required this.orgNames});

  final HkzOrgAdmin admin;
  final Map<String, String> orgNames;

  @override
  State<_HackzOrgAdminAssignmentsDialog> createState() => _HackzOrgAdminAssignmentsDialogState();
}

class _HackzOrgAdminAssignmentsDialogState extends State<_HackzOrgAdminAssignmentsDialog> {
  late Set<String> _assigned;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _assigned = widget.admin.assignedOrganisationIds.toSet();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final Set<String> original = widget.admin.assignedOrganisationIds.toSet();
      for (final String orgId in _assigned.difference(original)) {
        await HkzOrgAdminService.assignOrganisation(orgAdminId: widget.admin.id, organisationId: orgId);
      }
      for (final String orgId in original.difference(_assigned)) {
        await HkzOrgAdminService.removeOrganisationAssignment(orgAdminId: widget.admin.id, organisationId: orgId);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) FeedbackService.showError(context, title: 'Update failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> orgs = widget.orgNames.entries.toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) => a.value.compareTo(b.value));

    return AlertDialog(
      title: Text('Organisations — ${widget.admin.displayName}'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: orgs.isEmpty
            ? const Text('No organisations on the Control Plane yet.')
            : ListView.builder(
                itemCount: orgs.length,
                itemBuilder: (BuildContext context, int index) {
                  final MapEntry<String, String> entry = orgs[index];
                  final bool checked = _assigned.contains(entry.key);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: _busy
                        ? null
                        : (bool? value) {
                            setState(() {
                              if (value == true) {
                                _assigned.add(entry.key);
                              } else {
                                _assigned.remove(entry.key);
                              }
                            });
                          },
                    title: Text(entry.value),
                    subtitle: Text(entry.key, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? const HkzProgressIndicator(size: 18) : const Text('Save')),
      ],
    );
  }
}
