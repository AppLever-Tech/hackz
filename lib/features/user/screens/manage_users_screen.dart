import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/widgets/signup/account_workspace_visuals.dart';
import '../../../core/theme/app_icons.dart';
import '../../imports/imports.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../utils/firestore_utils.dart';
import '../../../features/dashboard/deptadmin/widgets/department_access_code_bar.dart';
import '../../../features/dashboard/chrome/empty_search_state.dart';
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_alert_dialog.dart';
import '../../../core/workspace/user_list_identity_lead.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/icon_only_filter_button.dart';
import '../widgets/mobile_user_list_row_card.dart';
import '../widgets/user_metrics_row.dart';
import '../models/enums/user_role.dart';
import '../models/enums/user_status.dart';
import '../models/user_model.dart';
import '../services/user_role_labels.dart';
import 'create_user_dialog.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({
    super.key,
    required this.user,
    this.initialUsersFilter = UsersFilter.all,
  });

  final UserModel user;
  final UsersFilter initialUsersFilter;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

enum UsersFilter { all, teamMembers, coordinators, pending, rejected }

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  UsersFilter _filter = UsersFilter.all;
  bool _copied = false;
  bool _showAccessCode = false;
  List<UserModel> _allUsers = <UserModel>[];
  String _inviteCode = '';
  String _orgName = '';

  OrganizationModel get _organization => OrganizationModel(
        id: widget.user.orgId,
        name: _orgName,
        type: widget.user.orgType ?? OrganizationType.college,
        address: '',
        website: '',
        contact: '',
        createdAt: DateTime.now(),
      );

  @override
  void initState() {
    super.initState();
    _filter = widget.initialUsersFilter;
    _orgName = widget.user.orgId;
    _searchController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: widget.user.orgId)
          .where('departmentCode', isEqualTo: DepartmentModel.resolveCode(widget.user.departmentCode))
          .get();
      final users = query.docs
          .map((d) => UserModel.fromMap(d.data()))
          .map((u) => u.userId.isNotEmpty ? u : u.copyWith(userId: u.phone))
          .toList(growable: false);
      final codeSnap = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzInviteCodes)
          .where('orgId', isEqualTo: widget.user.orgId)
          .where('departmentCode', isEqualTo: DepartmentModel.resolveCode(widget.user.departmentCode))
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      String orgName = widget.user.orgId;
      try {
        final OrganizationModel? org = await FirestoreUtils.fetchOrganization(widget.user.orgId);
        final String fetched = (org?.name ?? '').trim();
        if (fetched.isNotEmpty) orgName = fetched;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _inviteCode = codeSnap.docs.isEmpty ? '' : ((codeSnap.docs.first.data()['code'] as String?) ?? '').trim();
        _orgName = orgName;
      });
    } catch (_) {
      // Keep prior list on load failure.
    }
  }

  Future<void> _openImportUsers() async {
    final bool? imported = await showUserImportWorkflow(
      context: context,
      config: UserImportConfig(
        actor: widget.user,
        organizationType: widget.user.orgType ?? OrganizationType.college,
        departmentName: widget.user.department,
        departmentCode: DepartmentModel.resolveCode(widget.user.departmentCode),
      ),
    );
    if (imported == true && mounted) _loadAll();
  }

  Future<void> _openCreateUser() async {
    final changed = await showCreateUserDialog(
      context: context,
      roleOptions: <String>[UserRole.teamMember.code, UserRole.coordinator.code],
      initialRoleCode: UserRole.teamMember.code,
      organization: _organization,
      department: widget.user.department,
      onUserSaved: (savedUser) async {
        await FirestoreUtils.updateUser(
          savedUser.userId,
          <String, dynamic>{
            'orgId': widget.user.orgId,
            'department': widget.user.department,
            'departmentCode': DepartmentModel.resolveCode(widget.user.departmentCode),
          },
        );
      },
    );
    if (changed && mounted) _loadAll();
  }

  Future<void> _openEditUser(UserModel user) async {
    final changed = await showCreateUserDialog(
      context: context,
      roleOptions: <String>[UserRole.teamMember.code, UserRole.coordinator.code],
      organization: _organization,
      department: widget.user.department,
      initialUser: user,
    );
    if (changed && mounted) _loadAll();
  }

  Future<void> _approve(UserModel user) async {
    String selectedRole = UserRole.teamMember.code;
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => ResponsiveAlertDialog(
          title: const Text('Select Role'),
          widthPreset: DialogWidthPreset.compact,
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: UserRole.teamMember.code, child: Text(UserRoleLabels.labelForCode(UserRole.teamMember.code))),
              DropdownMenuItem<String>(value: 'COO', child: Text(UserRoleLabels.labelForCode('COO'))),
              DropdownMenuItem<String>(value: 'JUD', child: Text(UserRoleLabels.labelForCode('JUD'))),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedRole = value);
            },
          ),
          actions: <Widget>[
            OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(selectedRole), child: const Text('Approve')),
          ],
        ),
      ),
    );
    if (role == null) return;
    await FirestoreUtils.updateUser(user.userId, <String, dynamic>{
      'role': role,
      'status': UserStatus.active.value,
      'approvedBy': widget.user.userId,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': null,
    });
    if (mounted) _loadAll();
  }

  Future<void> _reject(UserModel user) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => ResponsiveAlertDialog(
        title: const Text('Reject user request'),
        widthPreset: DialogWidthPreset.standard,
        content: TextField(
          controller: reasonController,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Share a clear reason for the user record.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    final now = DateTime.now();
    await FirestoreUtils.updateUser(user.userId, <String, dynamic>{
      'status': UserStatus.rejected.value,
      'approvedBy': widget.user.userId,
      'approvedAt': Timestamp.fromDate(now),
      'rejectedAt': Timestamp.fromDate(now),
      'rejectionReason': reason.trim().isEmpty ? 'Rejected by department admin.' : reason.trim(),
    });
    if (mounted) _loadAll();
  }

  Future<void> _deleteUser(UserModel user) async {
    final displayName = '${user.firstName} ${user.lastName}'.trim().isEmpty
        ? user.phone
        : '${user.firstName} ${user.lastName}'.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ResponsiveAlertDialog(
        title: const Text('Delete user?'),
        widthPreset: DialogWidthPreset.compact,
        content: Text('This will remove $displayName from this department.'),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await FirestoreUtils.deleteUser(user.userId);
    if (mounted) _loadAll();
  }

  Future<void> _copyInviteCode() async {
    if (_inviteCode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _inviteCode));
    if (!mounted) return;
    setState(() => _copied = true);
    FeedbackService.showInfo(
      context,
      title: 'Copied',
      message: 'Invite code copied.',
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String _formatCode(String raw) {
    final code = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (code.length != 6) return raw;
    return '${code.substring(0, 3)}-${code.substring(3)}';
  }

  String _newInviteCode() {
    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    return ms.substring(ms.length - 6);
  }

  Future<void> _regenerateInviteCode() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ResponsiveAlertDialog(
        title: const Text('Regenerate invite code?'),
        widthPreset: DialogWidthPreset.compact,
        content: const Text('Existing active codes for this department will be deactivated.'),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (ok != true) return;
    final depCode = DepartmentModel.resolveCode(widget.user.departmentCode);
    final active = await FirebaseFirestore.instance
        .collection(FirestoreUtils.hkzInviteCodes)
        .where('orgId', isEqualTo: widget.user.orgId)
        .where('departmentCode', isEqualTo: depCode)
        .where('isActive', isEqualTo: true)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in active.docs) {
      batch.update(d.reference, <String, dynamic>{'isActive': false});
    }
    final doc = FirebaseFirestore.instance.collection(FirestoreUtils.hkzInviteCodes).doc();
    batch.set(doc, <String, dynamic>{
      'code': _newInviteCode(),
      'orgId': widget.user.orgId,
      'departmentCode': depCode,
      'department': widget.user.department,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (!mounted) return;
    await _loadAll();
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: 'Invite code regenerated',
      message: 'A new invite code is now active.',
    );
  }

  String _roleLabel(String role) => UserRoleLabels.labelForCode(role);

  List<UserModel> _filteredUsers() {
    final q = _searchController.text.trim().toLowerCase();
    return _allUsers.where((u) {
      final roleOk = switch (_filter) {
        UsersFilter.all => true,
        UsersFilter.teamMembers => u.role == UserRole.teamMember.code && u.status == UserStatus.active,
        UsersFilter.coordinators => u.role == 'COO' && u.status == UserStatus.active,
        UsersFilter.pending => u.status == UserStatus.pendingApproval,
        UsersFilter.rejected => u.status == UserStatus.rejected,
      };
      if (!roleOk) return false;
      if (q.isEmpty) return true;
      final blob = '${u.firstName} ${u.lastName} ${u.phone} ${u.email} ${u.rejectionReason ?? ''}'.toLowerCase();
      return blob.contains(q);
    }).toList(growable: false);
  }

  List<UserModel> _section(List<UserModel> users, {String? role, UserStatus? status}) {
    return users.where((u) {
      if (status != null) return u.status == status;
      if (role != null) return u.role == role && u.status == UserStatus.active;
      return false;
    }).toList(growable: false);
  }

  int _countForFilter(UsersFilter filter) {
    return switch (filter) {
      UsersFilter.all => _allUsers.length,
      UsersFilter.teamMembers => _allUsers.where((UserModel u) => u.role == UserRole.teamMember.code && u.status == UserStatus.active).length,
      UsersFilter.coordinators => _allUsers.where((UserModel u) => u.role == 'COO' && u.status == UserStatus.active).length,
      UsersFilter.pending => _allUsers.where((UserModel u) => u.status == UserStatus.pendingApproval).length,
      UsersFilter.rejected => _allUsers.where((UserModel u) => u.status == UserStatus.rejected).length,
    };
  }

  Widget _metaDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1))),
    );
  }

  Widget _inlineMeta(String text, {Color? color, int maxLines = 1}) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? const Color(0xFF64748B),
      ),
    );
  }

  Widget _userDetailsLine(UserModel u) {
    final isPending = u.status == UserStatus.pendingApproval;
    final isRejected = u.status == UserStatus.rejected;
    final String email = u.email.trim().isEmpty ? '—' : u.email.trim();
    final String phone = u.phone.trim().isEmpty ? '—' : u.phone.trim();
    final String typeLabel = isPending ? 'Pending approval' : _roleLabel(u.role);
    final rejectionReason = (u.rejectionReason ?? '').trim().isEmpty ? 'No reason recorded' : u.rejectionReason!.trim();

    final List<Widget> segments = <Widget>[
      UserListIdentityLead(user: u),
      _metaDot(),
      _inlineMeta(email),
      _metaDot(),
      _inlineMeta(phone),
      _metaDot(),
      _inlineMeta(typeLabel),
      if (u.status != UserStatus.active && !isPending) ...<Widget>[
        _metaDot(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AccountWorkspaceVisuals.chipBackgroundForUserStatus(u.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AccountWorkspaceVisuals.userStatusDisplayLabel(u.status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AccountWorkspaceVisuals.userStatusAccent(u.status),
            ),
          ),
        ),
      ],
      if (isRejected) ...<Widget>[
        _metaDot(),
        _inlineMeta('Reason: $rejectionReason', color: const Color(0xFF7F1D1D)),
      ],
    ];

    final Widget line = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: segments,
    );

    if (ResponsiveHelper.isMobile(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: line,
      );
    }
    return line;
  }

  Widget _editIconButton(UserModel u) {
    return IconButton(
      tooltip: 'Edit user',
      onPressed: () => _openEditUser(u),
      icon: const Icon(AppIcons.edit, size: 20),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _userRowTrailing(UserModel u) {
    final isPending = u.status == UserStatus.pendingApproval;
    if (isPending) {
      if (ResponsiveHelper.isMobile(context)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _editIconButton(u),
            IconButton(
              tooltip: 'Approve',
              onPressed: () => _approve(u),
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF177C50)),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              tooltip: 'Reject',
              onPressed: () => _reject(u),
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _editIconButton(u),
          TextButton(
            onPressed: () => _approve(u),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () => _reject(u),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Reject'),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _editIconButton(u),
        IconButton(
          tooltip: 'Delete user',
          onPressed: () => _deleteUser(u),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  List<Widget> _mobileUserRow2Extras(UserModel u) {
    final bool isPending = u.status == UserStatus.pendingApproval;
    final bool isRejected = u.status == UserStatus.rejected;
    final String rejectionReason =
        (u.rejectionReason ?? '').trim().isEmpty ? 'No reason recorded' : u.rejectionReason!.trim();

    final List<Widget> extras = <Widget>[];

    if (u.status != UserStatus.active && !isPending) {
      extras.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AccountWorkspaceVisuals.chipBackgroundForUserStatus(u.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AccountWorkspaceVisuals.userStatusDisplayLabel(u.status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AccountWorkspaceVisuals.userStatusAccent(u.status),
            ),
          ),
        ),
      );
    }

    if (isRejected) {
      extras.add(
        Text(
          'Reason: $rejectionReason',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7F1D1D),
            height: 1.3,
          ),
        ),
      );
    }

    return extras;
  }

  List<Widget> _mobileUserRowTrailing(UserModel u) {
    final bool isPending = u.status == UserStatus.pendingApproval;
    if (isPending) {
      return <Widget>[
        MobileRowCardIconAction(
          tooltip: 'Edit user',
          icon: AppIcons.edit,
          onTap: () => _openEditUser(u),
        ),
        MobileRowCardIconAction(
          tooltip: 'Approve',
          icon: AppIcons.workflowApproved,
          onTap: () => _approve(u),
          foregroundColor: const Color(0xFF177C50),
        ),
        MobileRowCardIconAction(
          tooltip: 'Reject',
          icon: AppIcons.workflowRejected,
          onTap: () => _reject(u),
          foregroundColor: MobileRowCardIconActionMetrics.dangerForegroundColor,
        ),
      ];
    }

    return <Widget>[
      MobileRowCardIconAction(
        tooltip: 'Edit user',
        icon: AppIcons.edit,
        onTap: () => _openEditUser(u),
      ),
      MobileRowCardIconAction(
        tooltip: 'Delete user',
        icon: AppIcons.remove,
        onTap: () => _deleteUser(u),
        foregroundColor: MobileRowCardIconActionMetrics.dangerForegroundColor,
      ),
    ];
  }

  Widget _mobileUserRow(UserModel u) {
    return MobileUserListRowCard(
      user: u,
      trailing: _mobileUserRowTrailing(u),
      extraRow2Items: _mobileUserRow2Extras(u),
    );
  }

  Widget _userRow(UserModel u) {
    if (ResponsiveHelper.isMobile(context)) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: _mobileUserRow(u),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(child: _userDetailsLine(u)),
          const SizedBox(width: 4),
          _userRowTrailing(u),
        ],
      ),
    );
  }

  Widget _roleAccordion({
    required String title,
    required int count,
    required List<UserModel> users,
    bool highlighted = false,
  }) {
    if (users.isEmpty) return const SizedBox.shrink();
    final Color headerBg = highlighted ? const Color(0xFFFFF4E8) : const Color(0xFFF6F8FD);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: headerBg,
        borderRadius: BorderRadius.circular(10),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Text(
              '$title ($count)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            children: users.map(_userRow).toList(growable: false),
          ),
        ),
      ),
    );
  }

  InputDecoration _searchDecoration() {
    return HackzInputDecoration.decorate(
      hintText: 'Search users',
      prefixIcon: const Icon(AppIcons.search, size: 18),
      contentPaddingOverride: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  static const Color _filterAll = Color(0xFF4A67FF);
  static const Color _filterTeamMember = Color(0xFF7C3AED);
  static const Color _filterCoordinator = Color(0xFF16A34A);
  static const Color _filterPending = Color(0xFFEA580C);
  static const Color _filterRejected = Color(0xFFB91C1C);

  Widget _userFilterIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconOnlyFilterButton(
          icon: AppIcons.users,
          tooltip: 'All',
          selected: _filter == UsersFilter.all,
          color: _filterAll,
          onTap: () => setState(() => _filter = UsersFilter.all),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.teamMember,
          tooltip: UserRoleLabels.labelForCode(UserRole.teamMember.code),
          selected: _filter == UsersFilter.teamMembers,
          color: _filterTeamMember,
          onTap: () => setState(() => _filter = UsersFilter.teamMembers),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.coordinator,
          tooltip: 'Coordinator',
          selected: _filter == UsersFilter.coordinators,
          color: _filterCoordinator,
          onTap: () => setState(() => _filter = UsersFilter.coordinators),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.pendingUsers,
          tooltip: 'Pending',
          selected: _filter == UsersFilter.pending,
          color: _filterPending,
          onTap: () => setState(() => _filter = UsersFilter.pending),
        ),
        IconOnlyFilterButton(
          icon: AppIcons.workflowRejected,
          tooltip: 'Rejected',
          selected: _filter == UsersFilter.rejected,
          color: _filterRejected,
          onTap: () => setState(() => _filter = UsersFilter.rejected),
        ),
      ],
    );
  }

  Widget _accessCodeToggle({required bool compact}) {
    return OutlinedButton(
      onPressed: () => setState(() => _showAccessCode = !_showAccessCode),
      style: MobileToolbarButtonStyles.outlined(compact: true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(AppIcons.key, size: 16),
          const SizedBox(width: 6),
          Text(compact ? 'Code' : 'Access Code'),
          const SizedBox(width: 2),
          Icon(_showAccessCode ? AppIcons.expandLess : AppIcons.expandMore, size: 18),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool canImport = !mobile && ImportPlatformSupport.isSupported(context);

    final Widget search = TextField(
      controller: _searchController,
      style: HackzInputDecoration.fieldTextStyle,
      decoration: _searchDecoration(),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (!mobile) ...<Widget>[
          FilledButton.icon(
            onPressed: _openCreateUser,
            icon: const Icon(AppIcons.add, size: 16),
            label: const Text('Create User'),
            style: MobileToolbarButtonStyles.filled(compact: true),
          ),
          const SizedBox(width: 8),
          if (canImport) ...<Widget>[
            OutlinedButton.icon(
              onPressed: _openImportUsers,
              icon: const Icon(AppIcons.attachments, size: 16),
              label: const Text('Import Users'),
              style: MobileToolbarButtonStyles.outlined(compact: true),
            ),
            const SizedBox(width: 8),
          ],
        ],
        _accessCodeToggle(compact: mobile),
        const SizedBox(width: 8),
        Expanded(child: search),
        const SizedBox(width: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: _userFilterIcons(),
        ),
      ],
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    final double bottomPadding = ResponsiveHelper.isMobile(context)
        ? MobileCreateFabStyles.listBottomPadding
        : 12;

    if (users.isEmpty) {
      return EmptySearchState.users(
        onClearSearch: () {
          if (_searchController.text.trim().isEmpty && _filter == UsersFilter.all) return;
          setState(() {
            _searchController.clear();
            _filter = UsersFilter.all;
          });
        },
      );
    }

    if (_filter != UsersFilter.all) {
      return ListView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        children: users.map(_userRow).toList(growable: false),
      );
    }

    final pending = _section(users, status: UserStatus.pendingApproval);
    final teamMembers = _section(users, role: UserRole.teamMember.code);
    final coordinators = _section(users, role: 'COO');
    final rejected = _section(users, status: UserStatus.rejected);

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: <Widget>[
        _roleAccordion(title: 'Pending Users', count: pending.length, users: pending, highlighted: true),
        _roleAccordion(title: UserRoleLabels.pluralLabelForCode(UserRole.teamMember.code), count: teamMembers.length, users: teamMembers),
        _roleAccordion(title: 'Coordinators', count: coordinators.length, users: coordinators),
        _roleAccordion(title: 'Rejected Users', count: rejected.length, users: rejected, highlighted: true),
      ],
    );
  }

  Widget _buildUserMetrics(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    return UserMetricsRow(
      teamMembers: _countForFilter(UsersFilter.teamMembers),
      coordinators: _countForFilter(UsersFilter.coordinators),
      pending: _countForFilter(UsersFilter.pending),
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
    );
  }

  Widget _buildContextSubtitle() {
    final String department = widget.user.department.trim().isEmpty
        ? DepartmentModel.resolveCode(widget.user.departmentCode)
        : widget.user.department.trim();
    final String org = _orgName.trim().isEmpty ? widget.user.orgId : _orgName.trim();
    return Row(
      children: <Widget>[
        const Icon(AppIcons.departments, size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            department.isEmpty ? '—' : department,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Icon(AppIcons.organizations, size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            org,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required double gap}) {
    final Widget metrics = _buildUserMetrics(context);
    final Widget accessCodeBar = DepartmentAccessCodeBar(
      displayCode: _formatCode(_inviteCode),
      rawCode: _inviteCode,
      copied: _copied,
      onCopy: _copyInviteCode,
      onRegenerate: _regenerateInviteCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildContextSubtitle(),
        SizedBox(height: gap),
        metrics,
        SizedBox(height: gap),
        _buildToolbar(context),
        AnimatedCrossFade(
          alignment: Alignment.topCenter,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: accessCodeBar,
          ),
          crossFadeState: _showAccessCode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final double gap = ResponsiveHelper.dashboardSectionGap(context);
    final List<UserModel> users = _filteredUsers();
    final Widget header = _buildHeader(context, gap: gap);
    final Widget userList = _buildUserList(users);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        if (!hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              SizedBox(height: 480, child: userList),
            ],
          );
        }

        if (mobile) {
          return Stack(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Expanded(child: userList),
                ],
              ),
              MobileCreateFab(
                onPressed: _openCreateUser,
                tooltip: 'Create User',
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            Expanded(child: userList),
          ],
        );
      },
    );
  }
}
