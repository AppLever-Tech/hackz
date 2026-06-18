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
import '../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../core/responsive/mobile_filter_pane_styles.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_alert_dialog.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/workspace/user_list_identity_lead.dart';
import '../../../core/ui/common/mobile_compact_pill.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../widgets/mobile_user_list_row_card.dart';
import '../widgets/user_metrics_row.dart';
import '../models/enums/user_status.dart';
import '../models/user_model.dart';
import 'create_user_dialog.dart';
import '../../../core/ui/inputs/filter_pill.dart';

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

enum UsersFilter { all, faculty, students, coordinators, pending, rejected }

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  UsersFilter _filter = UsersFilter.all;
  bool _showFilters = false;
  bool _copied = false;
  List<UserModel> _allUsers = <UserModel>[];
  String _inviteCode = '';

  OrganizationModel get _organization => OrganizationModel(
        id: widget.user.orgId,
        name: '',
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
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _inviteCode = codeSnap.docs.isEmpty ? '' : ((codeSnap.docs.first.data()['code'] as String?) ?? '').trim();
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
      roleOptions: const <String>['FAC', 'STU', 'COO'],
      initialRoleCode: 'STU',
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
      roleOptions: const <String>['FAC', 'STU', 'COO'],
      organization: _organization,
      department: widget.user.department,
      initialUser: user,
    );
    if (changed && mounted) _loadAll();
  }

  Future<void> _approve(UserModel user) async {
    String selectedRole = 'STU';
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
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'FAC', child: Text('Faculty')),
              DropdownMenuItem<String>(value: 'STU', child: Text('Student')),
              DropdownMenuItem<String>(value: 'COO', child: Text('Coordinator')),
              DropdownMenuItem<String>(value: 'JUD', child: Text('Judge')),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'FAC':
        return 'Faculty';
      case 'COO':
        return 'Coordinator';
      case 'STU':
      default:
        return 'Student';
    }
  }

  List<UserModel> _filteredUsers() {
    final q = _searchController.text.trim().toLowerCase();
    return _allUsers.where((u) {
      final roleOk = switch (_filter) {
        UsersFilter.all => true,
        UsersFilter.faculty => u.role == 'FAC' && u.status == UserStatus.active,
        UsersFilter.students => u.role == 'STU' && u.status == UserStatus.active,
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
      UsersFilter.faculty => _allUsers.where((UserModel u) => u.role == 'FAC' && u.status == UserStatus.active).length,
      UsersFilter.students => _allUsers.where((UserModel u) => u.role == 'STU' && u.status == UserStatus.active).length,
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
          icon: AppIcons.statusRejected,
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

  bool get _hasActiveFilter => _filter != UsersFilter.all;

  void _clearAllFilters() {
    setState(() => _filter = UsersFilter.all);
  }

  InputDecoration _searchDecoration(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return InputDecoration(
      hintText: 'Search users',
      prefixIcon: const Icon(AppIcons.search),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFCFDFF),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: mobile ? 10 : 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.3),
      ),
    );
  }

  Widget _userFilterChip({
    required bool compact,
    required UsersFilter filter,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _filter == filter;
    final int count = _countForFilter(filter);
    void selectFilter() => setState(() => _filter = filter);

    if (!compact) {
      return FilterPill(
        selected: selected,
        icon: icon,
        label: label,
        count: count,
        onTap: selectFilter,
      );
    }

    final String text = count == 0 ? label : '$label ($count)';
    return MobileCompactPill(
      label: text,
      icon: icon,
      selected: selected,
      onTap: selectFilter,
    );
  }

  Widget _buildMobileFiltersPanel(BuildContext context) {
    final bool compact = MobileFilterPaneStyles.useCompact(context);
    final double chipGap = MobileFilterPaneStyles.chipGap(compact: compact);

    return MobileFilterPaneStyles.panelShell(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveFilterChipRow(
            spacing: chipGap,
            runSpacing: chipGap,
            children: <Widget>[
              _userFilterChip(compact: compact, filter: UsersFilter.all, icon: AppIcons.users, label: 'All'),
              _userFilterChip(compact: compact, filter: UsersFilter.faculty, icon: AppIcons.faculty, label: 'Faculty'),
              _userFilterChip(compact: compact, filter: UsersFilter.students, icon: AppIcons.student, label: 'Student'),
              _userFilterChip(
                compact: compact,
                filter: UsersFilter.coordinators,
                icon: AppIcons.coordinator,
                label: 'Coordinator',
              ),
              _userFilterChip(compact: compact, filter: UsersFilter.pending, icon: AppIcons.pendingUsers, label: 'Pending'),
              _userFilterChip(
                compact: compact,
                filter: UsersFilter.rejected,
                icon: AppIcons.statusRejected,
                label: 'Rejected',
              ),
            ],
          ),
          SizedBox(height: MobileFilterPaneStyles.sectionGap(compact: compact)),
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: _clearAllFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    if (!_hasActiveFilter) return const SizedBox.shrink();

    final (IconData icon, String label) = switch (_filter) {
      UsersFilter.faculty => (AppIcons.faculty, 'Faculty'),
      UsersFilter.students => (AppIcons.student, 'Student'),
      UsersFilter.coordinators => (AppIcons.coordinator, 'Coordinator'),
      UsersFilter.pending => (AppIcons.pendingUsers, 'Pending'),
      UsersFilter.rejected => (AppIcons.statusRejected, 'Rejected'),
      UsersFilter.all => (AppIcons.users, 'All'),
    };
    final int count = _countForFilter(_filter);
    final String text = count == 0 ? label : '$label ($count)';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        MobileCompactPill(
          label: text,
          icon: icon,
          selected: true,
          onDeleted: _clearAllFilters,
        ),
      ],
    );
  }

  Widget _buildSearchToolbar(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResponsiveSearchFilterBar(
            searchController: _searchController,
            searchHint: 'Search users',
            searchDecoration: _searchDecoration(context),
            filtersExpanded: _showFilters,
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            iconOnlyFilterOnMobile: true,
          ),
          const SizedBox(height: 6),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMobileFiltersPanel(context),
            crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          if (_hasActiveFilter) ...<Widget>[
            const SizedBox(height: 6),
            _buildActiveFiltersRow(),
          ],
        ],
      );
    }

    return ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search users',
      searchDecoration: _searchDecoration(context),
      showFilterButton: false,
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    final double bottomPadding = ResponsiveHelper.isMobile(context)
        ? MobileCreateFabStyles.listBottomPadding
        : 12;

    if (users.isEmpty) {
      return const Center(child: Text('No users match the selected filter.'));
    }

    if (_filter != UsersFilter.all) {
      return ListView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        children: users.map(_userRow).toList(growable: false),
      );
    }

    final pending = _section(users, status: UserStatus.pendingApproval);
    final faculty = _section(users, role: 'FAC');
    final students = _section(users, role: 'STU');
    final coordinators = _section(users, role: 'COO');
    final rejected = _section(users, status: UserStatus.rejected);

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: <Widget>[
        _roleAccordion(title: 'Pending Users', count: pending.length, users: pending, highlighted: true),
        _roleAccordion(title: 'Faculty', count: faculty.length, users: faculty),
        _roleAccordion(title: 'Students', count: students.length, users: students),
        _roleAccordion(title: 'Coordinators', count: coordinators.length, users: coordinators),
        _roleAccordion(title: 'Rejected Users', count: rejected.length, users: rejected, highlighted: true),
      ],
    );
  }

  Widget _buildCreateImportToolbar(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return const SizedBox.shrink();
    }

    final Widget createButton = FilledButton.icon(
      onPressed: _openCreateUser,
      icon: const Icon(AppIcons.add, size: 16),
      label: const Text('Create User'),
      style: MobileToolbarButtonStyles.filled(compact: false),
    );

    if (!ImportPlatformSupport.isSupported(context)) {
      return Row(mainAxisSize: MainAxisSize.min, children: <Widget>[createButton]);
    }

    final Widget importButton = OutlinedButton.icon(
      onPressed: _openImportUsers,
      icon: const Icon(AppIcons.attachments, size: 16),
      label: const Text('Import Users'),
      style: MobileToolbarButtonStyles.outlined(compact: false),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        createButton,
        const SizedBox(width: 8),
        importButton,
      ],
    );
  }

  Widget _buildUserMetrics(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    return UserMetricsRow(
      faculty: _countForFilter(UsersFilter.faculty),
      students: _countForFilter(UsersFilter.students),
      coordinators: _countForFilter(UsersFilter.coordinators),
      pending: _countForFilter(UsersFilter.pending),
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
    );
  }

  Widget _buildHeader(BuildContext context, {required double gap}) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget metrics = _buildUserMetrics(context);
    final Widget accessCodeBar = DepartmentAccessCodeBar(
      displayCode: _formatCode(_inviteCode),
      rawCode: _inviteCode,
      copied: _copied,
      onCopy: _copyInviteCode,
      onRegenerate: _regenerateInviteCode,
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          metrics,
          const SizedBox(height: 8),
          accessCodeBar,
          const SizedBox(height: 8),
          _buildSearchToolbar(context),
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        metrics,
        SizedBox(height: gap),
        _buildCreateImportToolbar(context),
        SizedBox(height: gap),
        accessCodeBar,
        SizedBox(height: gap),
        ResponsiveFilterChipRow(
          children: <Widget>[
            _userFilterChip(compact: false, filter: UsersFilter.all, icon: AppIcons.users, label: 'All'),
            _userFilterChip(compact: false, filter: UsersFilter.faculty, icon: AppIcons.faculty, label: 'Faculty'),
            _userFilterChip(compact: false, filter: UsersFilter.students, icon: AppIcons.student, label: 'Student'),
            _userFilterChip(
              compact: false,
              filter: UsersFilter.coordinators,
              icon: AppIcons.coordinator,
              label: 'Coordinator',
            ),
            _userFilterChip(compact: false, filter: UsersFilter.pending, icon: AppIcons.pendingUsers, label: 'Pending'),
            _userFilterChip(
              compact: false,
              filter: UsersFilter.rejected,
              icon: AppIcons.statusRejected,
              label: 'Rejected',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchToolbar(context),
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
