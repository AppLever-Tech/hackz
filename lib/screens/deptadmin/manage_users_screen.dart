import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/app_icons.dart';
import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/department_model.dart';
import '../../models/enums/user_status.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../common/create_user_dialog.dart';
import '../common/dashboard_components.dart';
import '../../widgets/filter_pill.dart';

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

enum UsersFilter { all, pending, faculty, students, coordinators }

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
    setState(() => _refreshing = true);
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
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select Role'),
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
    await FirestoreUtils.updateUser(user.userId, <String, dynamic>{
      'status': UserStatus.rejected.value,
      'approvedBy': widget.user.userId,
      'approvedAt': Timestamp.fromDate(DateTime.now()),
    });
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
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate invite code?'),
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
        UsersFilter.pending => u.status == UserStatus.pending,
        UsersFilter.faculty => u.role == 'FAC',
        UsersFilter.students => u.role == 'STU',
        UsersFilter.coordinators => u.role == 'COO',
      };
      if (!roleOk) return false;
      if (q.isEmpty) return true;
      final blob = '${u.firstName} ${u.lastName} ${u.phone} ${u.email}'.toLowerCase();
      return blob.contains(q);
    }).toList(growable: false);
  }

  List<UserModel> _section(List<UserModel> users, {String? role, UserStatus? status}) {
    return users.where((u) {
      if (status != null) return u.status == status;
      if (role != null) return u.role == role && u.status != UserStatus.pending;
      return false;
    }).toList(growable: false);
  }

  int _countForFilter(UsersFilter filter) {
    return switch (filter) {
      UsersFilter.all => _allUsers.length,
      UsersFilter.pending => _allUsers.where((UserModel u) => u.status == UserStatus.pending).length,
      UsersFilter.faculty => _allUsers.where((UserModel u) => u.role == 'FAC').length,
      UsersFilter.students => _allUsers.where((UserModel u) => u.role == 'STU').length,
      UsersFilter.coordinators => _allUsers.where((UserModel u) => u.role == 'COO').length,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _inviteCode.isEmpty ? null : _copyInviteCode,
                      icon: Icon(_copied ? AppIcons.copied : AppIcons.copy, size: 16),
                      label: Text(_copied ? 'Copied' : 'Copy'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Regenerate code',
                      onPressed: _regenerateInviteCode,
                      icon: const Icon(AppIcons.refresh),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int count, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF4E8) : const Color(0xFFF6F8FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('($count)', style: const TextStyle(color: Color(0xFF5F6684))),
        ],
      ),
    );
  }

  Widget _userRow(UserModel u) {
    final isPending = u.status == UserStatus.pending;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECF6)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEAF2FF),
            child: Icon(AppIcons.forUserRoleCode(u.role), size: 16, color: const Color(0xFF3552CC)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${u.firstName} ${u.lastName}'.trim(), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${u.phone} • ${u.email}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
              child: Text(_roleLabel(u.role), style: const TextStyle(fontSize: 12)),
            ),
          if (u.status != UserStatus.active) ...<Widget>[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: u.status == UserStatus.pending ? const Color(0xFFFFF1E4) : const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(u.status.value, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(width: 8),
          if (isPending) ...<Widget>[
            TextButton(onPressed: () => _approve(u), child: const Text('Approve')),
            TextButton(onPressed: () => _reject(u), child: const Text('Reject')),
          ] else
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.more, size: 18),
              onSelected: (v) async {
                if (v == 'delete') {
                  await FirestoreUtils.deleteUser(u.userId);
                  if (mounted) _loadAll();
                }
              },
              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final users = _filteredUsers();
    final pending = _section(users, status: UserStatus.pending);
    final faculty = _section(users, role: 'FAC');
    final students = _section(users, role: 'STU');
    final coordinators = _section(users, role: 'COO');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterPill(
                  selected: _filter == UsersFilter.all,
                  icon: AppIcons.users,
                  label: 'All',
                  count: _countForFilter(UsersFilter.all),
                  onTap: () => setState(() => _filter = UsersFilter.all),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterPill(
                  selected: _filter == UsersFilter.pending,
                  icon: AppIcons.pendingUsers,
                  label: 'Pending',
                  count: _countForFilter(UsersFilter.pending),
                  onTap: () => setState(() => _filter = UsersFilter.pending),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterPill(
                  selected: _filter == UsersFilter.faculty,
                  icon: AppIcons.faculty,
                  label: 'Faculty',
                  count: _countForFilter(UsersFilter.faculty),
                  onTap: () => setState(() => _filter = UsersFilter.faculty),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterPill(
                  selected: _filter == UsersFilter.students,
                  icon: AppIcons.student,
                  label: 'Students',
                  count: _countForFilter(UsersFilter.students),
                  onTap: () => setState(() => _filter = UsersFilter.students),
                ),
              ),
              FilterPill(
                selected: _filter == UsersFilter.coordinators,
                icon: AppIcons.coordinator,
                label: 'Coordinators',
                count: _countForFilter(UsersFilter.coordinators),
                onTap: () => setState(() => _filter = UsersFilter.coordinators),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users',
                  isDense: true,
                  prefixIcon: const Icon(AppIcons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _openCreateUser,
              icon: const Icon(AppIcons.add, size: 16),
              label: const Text('Create User'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: CustomScrollView(
            slivers: <Widget>[
              if (pending.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(child: _sectionHeader('Pending Users', pending.length, highlighted: true)),
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) => _userRow(pending[i]), childCount: pending.length),
                ),
              ],
              if (faculty.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 10), child: _sectionHeader('Faculty', faculty.length))),
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) => _userRow(faculty[i]), childCount: faculty.length),
                ),
              ],
              if (students.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 10), child: _sectionHeader('Students', students.length))),
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) => _userRow(students[i]), childCount: students.length),
                ),
              ],
              if (coordinators.isNotEmpty) ...<Widget>[
                SliverToBoxAdapter(
                    child: Padding(padding: const EdgeInsets.only(top: 10), child: _sectionHeader('Coordinators', coordinators.length))),
                SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) => _userRow(coordinators[i]), childCount: coordinators.length),
                ),
              ],
              if (users.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No users match the selected filter.')),
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
          Row(
            children: <Widget>[
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: const <Tab>[
                    Tab(text: 'Overview'),
                    Tab(text: 'Users'),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshing ? null : _loadAll,
                icon: const Icon(AppIcons.refresh),
              ),
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
