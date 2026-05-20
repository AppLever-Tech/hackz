import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_icons.dart';
import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/department_model.dart';
import '../../models/enums/user_status.dart';
import '../../models/user_model.dart';
import '../../constants/account_workspace_visuals.dart';
import '../../utils/firestore_utils.dart';
import '../common/create_user_dialog.dart';
import '../common/dashboard_components.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/common/rich_tabs.dart';
import '../../widgets/filter_pill.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';
import '../../widgets/responsive/responsive_filter_bar.dart';
import '../../widgets/common/context_pill.dart';
import '../../widgets/common/context_pill_theme.dart';
import '../../workspace/workspace.dart';
import '../common/app_dialog_template.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
    this.initialUsersFilter = UsersFilter.all,
  });

  final UserModel user;
  final int initialTabIndex;
  final UsersFilter initialUsersFilter;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

enum UsersFilter { all, faculty, students, coordinators, pending, rejected }

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  UsersFilter _filter = UsersFilter.all;
  bool _refreshing = false;
  bool _copied = false;
  List<UserModel> _allUsers = <UserModel>[];
  String _inviteCode = '';
  String _orgName = '';

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
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 1));
    _searchController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final orgDoc = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzOrganizations)
          .doc(widget.user.orgId)
          .get();
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _inviteCode = codeSnap.docs.isEmpty ? '' : ((codeSnap.docs.first.data()['code'] as String?) ?? '').trim();
        _orgName = ((orgDoc.data()?['name'] as String?) ?? '').trim();
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
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

  Future<void> _approve(UserModel user) async {
    String selectedRole = 'STU';
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => ResponsiveAlertDialog(
          title: const Text('Select Role'),
          widthPreset: DialogWidthPreset.compact,
          content: DropdownButtonFormField<String>(
            value: selectedRole,
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
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
    if (mounted) {
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code regenerated')));
    }
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

  Widget _overviewLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFF5F6684)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final deptName = DepartmentModel.byCode(widget.user.departmentCode)?.name ?? widget.user.departmentCode;
    final adminName = '${widget.user.firstName} ${widget.user.lastName}'.trim();
    final collegeDisplay = _orgName.isEmpty ? widget.user.orgId : _orgName;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _overviewLine(AppIcons.departments, deptName),
                _overviewLine(AppIcons.organizations, collegeDisplay),
                _overviewLine(AppIcons.adminProfile, adminName.isEmpty ? '—' : adminName),
                _overviewLine(AppIcons.phone, widget.user.phone),
                _overviewLine(AppIcons.email, widget.user.email),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Access Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, _) {
                    final codeField = Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(AppIcons.key, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inviteCode.isEmpty ? 'No active invite code' : _formatCode(_inviteCode),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                    final actions = <Widget>[
                      OutlinedButton.icon(
                        onPressed: _inviteCode.isEmpty ? null : _copyInviteCode,
                        icon: Icon(_copied ? AppIcons.copied : AppIcons.copy, size: 16),
                        label: Text(_copied ? 'Copied' : 'Copy'),
                      ),
                      IconButton(
                        tooltip: 'Regenerate code',
                        onPressed: _regenerateInviteCode,
                        icon: const Icon(AppIcons.refresh),
                      ),
                    ];
                    if (ResponsiveHelper.isMobile(context)) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          codeField,
                          const SizedBox(height: 8),
                          ResponsiveWrapToolbar(children: actions),
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: codeField),
                        const SizedBox(width: 8),
                        ...actions,
                      ],
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
    final String name = '${u.firstName} ${u.lastName}'.trim().isEmpty ? u.phone : '${u.firstName} ${u.lastName}'.trim();
    final String email = u.email.trim().isEmpty ? '—' : u.email.trim();
    final String phone = u.phone.trim().isEmpty ? '—' : u.phone.trim();
    final String typeLabel = isPending ? 'Pending approval' : _roleLabel(u.role);
    final rejectionReason = (u.rejectionReason ?? '').trim().isEmpty ? 'No reason recorded' : u.rejectionReason!.trim();

    final List<Widget> segments = <Widget>[
      ContextPill(
        label: name,
        semantic: ContextPillSemantic.user,
        icon: AppIcons.forUserRoleCode(u.role),
        onTap: () => WorkspaceNavigator.openUser(context, u.userId),
        compact: true,
        fitContent: true,
      ),
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

  Widget _userRowTrailing(UserModel u) {
    final isPending = u.status == UserStatus.pendingApproval;
    if (isPending) {
      if (ResponsiveHelper.isMobile(context)) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
    return IconButton(
      tooltip: 'Delete user',
      onPressed: () => _deleteUser(u),
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _userRow(UserModel u) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 8 : 10,
        vertical: 8,
      ),
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

  Widget _filterPill(UsersFilter filter, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterPill(
        selected: _filter == filter,
        icon: icon,
        label: label,
        count: _countForFilter(filter),
        onTap: () => setState(() => _filter = filter),
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = _filteredUsers();
    final pending = _section(users, status: UserStatus.pendingApproval);
    final faculty = _section(users, role: 'FAC');
    final students = _section(users, role: 'STU');
    final coordinators = _section(users, role: 'COO');
    final rejected = _section(users, status: UserStatus.rejected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ResponsiveFilterChipRow(
          children: <Widget>[
            _filterPill(UsersFilter.all, AppIcons.users, 'All'),
            _filterPill(UsersFilter.faculty, AppIcons.faculty, 'Faculty'),
            _filterPill(UsersFilter.students, AppIcons.student, 'Student'),
            _filterPill(UsersFilter.coordinators, AppIcons.coordinator, 'Coordinator'),
            _filterPill(UsersFilter.pending, AppIcons.pendingUsers, 'Pending'),
            _filterPill(UsersFilter.rejected, AppIcons.statusRejected, 'Rejected'),
          ],
        ),
        const SizedBox(height: 12),
        ResponsiveSearchFilterBar(
          searchController: _searchController,
          searchHint: 'Search users',
          showFilterButton: false,
          trailing: <Widget>[
            FilledButton.icon(
              onPressed: _openCreateUser,
              icon: const Icon(AppIcons.add, size: 16),
              label: const Text('Create User'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('No users match the selected filter.'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 12),
                  children: <Widget>[
                    _roleAccordion(title: 'Pending Users', count: pending.length, users: pending, highlighted: true),
                    _roleAccordion(title: 'Faculty', count: faculty.length, users: faculty),
                    _roleAccordion(title: 'Students', count: students.length, users: students),
                    _roleAccordion(title: 'Coordinators', count: coordinators.length, users: coordinators),
                    _roleAccordion(
                      title: 'Rejected Users',
                      count: rejected.length,
                      users: rejected,
                      highlighted: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RichTabBar(
            controller: _tabController,
            tabs: const <RichTabItem>[
              RichTabItem('Overview'),
              RichTabItem('Users'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildOverviewTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
