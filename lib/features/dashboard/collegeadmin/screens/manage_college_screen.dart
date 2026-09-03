import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../features/domain/services/domain_service.dart';
import '../../../../features/organization/models/department_model.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../features/organization/models/enums/organization_type.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/user/models/enums/user_status.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../../core/ui/common/count_pill.dart';
import '../../../../core/ui/common/page_header_context_pill.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../features/user/screens/create_user_dialog.dart';
import '../../chrome/dashboard_chrome_controller.dart';
import '../../chrome/dashboard_chrome_scope.dart';
import '../../chrome/dashboard_components.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/buttons/mobile_create_fab.dart';
import '../../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/hackz_select_field.dart';
import '../../../../core/responsive/responsive_filter_bar.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/workspace/user_workspace_avatar.dart';

class ManageCollegeScreen extends StatefulWidget {
  const ManageCollegeScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ManageCollegeScreen> createState() => _ManageCollegeScreenState();
}

class _ManageCollegeScreenState extends State<ManageCollegeScreen> {
  String _orgName = '';
  DashboardChromeController? _chrome;
  late Future<List<Map<String, dynamic>>> _departmentsFuture;

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
    _orgName = widget.user.orgId;
    _departmentsFuture = FirestoreUtils.getDepartmentsByCollege(widget.user.orgId);
    _loadOrganization();
  }

  void _reloadDepartments() {
    setState(() {
      _departmentsFuture = FirestoreUtils.getDepartmentsByCollege(widget.user.orgId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chrome ??= DashboardChromeScope.maybeOf(context);
    _syncHeaderContext();
  }

  void _syncHeaderContext() {
    _chrome?.setHeaderContextPills(<PageHeaderContextItem>[
      PageHeaderContextItem.organization(_orgName),
    ]);
  }

  Future<void> _loadOrganization() async {
    try {
      final OrganizationModel? org = await FirestoreUtils.fetchOrganization(widget.user.orgId);
      final String name = (org?.name ?? '').trim();
      if (!mounted) return;
      setState(() => _orgName = name.isEmpty ? widget.user.orgId : name);
      _syncHeaderContext();
    } catch (_) {
      if (!mounted) return;
      setState(() => _orgName = widget.user.orgId);
      _syncHeaderContext();
    }
  }

  Future<void> _openEditDepartmentAdmin(Map<String, dynamic> dept, UserModel adminUser) async {
    final changed = await showCreateUserDialog(
      context: context,
      roleCode: 'DADM',
      organization: _organization,
      department: ((dept['name'] as String?) ?? '').trim(),
      initialUser: adminUser,
    );
    if (mounted && changed) _reloadDepartments();
  }

  Future<void> _openDepartmentAdminDialog(Map<String, dynamic> dept) async {
    final changed = await showCreateUserDialog(
      context: context,
      roleCode: 'DADM',
      organization: _organization,
      department: ((dept['name'] as String?) ?? '').trim(),
      onUserSaved: (savedUser) async {
        final departmentId = ((dept['id'] as String?) ?? '').trim();
        if (departmentId.isEmpty) return;
        final departmentName = ((dept['name'] as String?) ?? '').trim();
        final departmentCode = ((dept['code'] as String?) ?? '').trim();
        await FirestoreUtils.setDepartmentAdmin(
          departmentId: departmentId,
          adminUserId: savedUser.userId,
        );
        await FirestoreUtils.updateUser(savedUser.userId, <String, dynamic>{
          'role': 'DADM',
          'department': departmentName,
          'departmentCode': DepartmentModel.resolveCode(departmentCode.isEmpty ? departmentName : departmentCode),
          'orgId': widget.user.orgId,
        });
      },
    );
    if (mounted && changed) _reloadDepartments();
  }

  Future<void> _removeDepartmentAdmin(
    Map<String, dynamic> dept, {
    required String adminUserId,
    required String adminName,
  }) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Remove department admin?',
      message: 'Remove $adminName from this department?',
      confirmLabel: 'Remove',
      dangerConfirm: true,
    );
    if (!ok) return;

    final departmentId = ((dept['id'] as String?) ?? '').trim();
    if (departmentId.isEmpty || adminUserId.trim().isEmpty) return;
    await FirestoreUtils.clearDepartmentAdmin(departmentId: departmentId);
    await FirestoreUtils.updateUser(adminUserId, <String, dynamic>{
      'department': '',
      'departmentCode': '',
    });
    if (mounted) _reloadDepartments();
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final String departmentId = ((dept['id'] as String?) ?? '').trim();
    final String name = ((dept['name'] as String?) ?? 'this department').trim();
    if (departmentId.isEmpty) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Cannot delete department',
        message: 'This department cannot be deleted because it has no department record.',
      );
      return;
    }

    final int teamMemberCount = (dept['teamMemberCount'] as int?) ?? 0;
    final String adminUserId = ((dept['adminUserId'] as String?) ?? '').trim();
    final bool hasUsers = teamMemberCount > 0;
    final bool hasAdmin = adminUserId.isNotEmpty;

    final StringBuffer warning = StringBuffer('Delete "$name"?');
    if (hasUsers || hasAdmin) {
      warning.write('\n\nThis removes the department record from your college.');
      final List<String> parts = <String>[];
      if (teamMemberCount > 0) parts.add('$teamMemberCount team members');
      if (hasAdmin) parts.add('the assigned department admin');
      if (parts.isNotEmpty) {
        warning.write(' ${parts.join(', ')} will remain in the college but are no longer tied to this department entry.');
      }
    }
    warning.write('\n\nThis cannot be undone.');

    final bool confirmed = await FeedbackService.showConfirmation(
      context,
      title: 'Delete department?',
      message: warning.toString(),
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!confirmed) return;

    try {
      if (hasAdmin) {
        await FirestoreUtils.clearDepartmentAdmin(departmentId: departmentId);
        await FirestoreUtils.updateUser(adminUserId, <String, dynamic>{
          'department': '',
          'departmentCode': '',
        });
      }
      await FirestoreUtils.deleteDepartment(departmentId: departmentId);
      if (!mounted) return;
      _reloadDepartments();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Delete failed',
        message: 'Could not delete department: $e',
      );
    }
  }

  Future<void> _showAddDepartmentDialog() async {
    final customDepartmentController = TextEditingController();
    String? selectedDepartment;
    bool useCustomDepartment = false;
    bool isSaving = false;

    final shouldRefresh = await showAppDialog<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
            Future<void> submit() async {
              final departmentName = useCustomDepartment
                  ? customDepartmentController.text.trim()
                  : (selectedDepartment ?? '').trim();
              if (departmentName.isEmpty) {
                FeedbackService.showWarning(
                  context,
                  title: 'Department required',
                  message: 'Please select or enter a department',
                );
                return;
              }

              final departmentCode = _resolveDepartmentCode(departmentName);
              setState(() => isSaving = true);
              var didPop = false;
              try {
                final String departmentId = await FirestoreUtils.addDepartment(
                  orgId: widget.user.orgId,
                  name: departmentName,
                  code: departmentCode,
                );
                await DomainService.ensureGeneralProblem(
                  orgId: widget.user.orgId,
                  departmentId: departmentId,
                );
                if (!context.mounted) return;
                didPop = true;
                Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  FeedbackService.showError(
                    context,
                    title: 'Could not add department',
                    message: '$e',
                  );
                }
              } finally {
                if (!didPop && context.mounted) {
                  setState(() => isSaving = false);
                }
              }
            }

            return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(AppIcons.departments, color: Color(0xFF6A38FF), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add Department',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('Existing list'),
                          selected: !useCustomDepartment,
                          onSelected: isSaving
                              ? null
                              : (_) => setState(() {
                                    useCustomDepartment = false;
                                  }),
                        ),
                        ChoiceChip(
                          label: const Text('New department'),
                          selected: useCustomDepartment,
                          onSelected: isSaving
                              ? null
                              : (_) => setState(() {
                                    useCustomDepartment = true;
                                  }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Department',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (useCustomDepartment)
                      TextField(
                        controller: customDepartmentController,
                        autofocus: true,
                        enabled: !isSaving,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter department name',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: const Icon(
                            AppIcons.departments,
                            size: 20,
                            color: Color(0xFF64748B),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!isSaving) submit();
                        },
                      )
                    else
                      HackzSelectField<String>(
                        value: selectedDepartment,
                        hint: 'Select department',
                        prefixIcon: AppIcons.departments,
                        enabled: !isSaving,
                        options: DepartmentModel.masterNames,
                        labelBuilder: (String name) => name,
                        iconBuilder: (_) => AppIcons.departments,
                        onChanged: (String name) => setState(() => selectedDepartment = name),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FilledButton(
                          onPressed: isSaving ? null : submit,
                          child: Text(isSaving ? 'Saving...' : 'Add'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
            );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      customDepartmentController.dispose();
    });
    if (mounted && shouldRefresh == true) _reloadDepartments();
  }

  String _resolveDepartmentCode(String departmentName) {
    final master = DepartmentModel.byName(departmentName);
    if (master != null) return master.code;
    final words = departmentName
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[^A-Za-z0-9]'), ''))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length > 1) {
      return words.map((word) => word[0]).join().toUpperCase();
    }
    final compact = departmentName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return compact.length <= 6 ? compact : compact.substring(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _departmentsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load departments: ${snapshot.error}');
        }
        final departments = snapshot.data ?? <Map<String, dynamic>>[];
        final int deptCount = departments.length;
        final isMobile = ResponsiveHelper.isMobile(context);

        final Widget title = Text(
          'Departments ($deptCount)',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        );
        final Widget addDepartmentButton = FilledButton.icon(
          onPressed: _showAddDepartmentDialog,
          icon: const Icon(AppIcons.add),
          label: const Text('Add Department'),
        );
        final Widget departmentList = departments.isEmpty
            ? Text(
                'No departments available for this college.',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            : isMobile
                ? ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: departments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (BuildContext context, int index) {
                      final dept = departments[index];
                      return _DepartmentCard(
                        department: dept,
                        onAddAdmin: () => _openDepartmentAdminDialog(dept),
                        onEditAdmin: (UserModel adminUser) => _openEditDepartmentAdmin(dept, adminUser),
                        onRemoveAdmin: (String adminUserId, String adminName) =>
                            _removeDepartmentAdmin(
                          dept,
                          adminUserId: adminUserId,
                          adminName: adminName,
                        ),
                        onDelete: () => _deleteDepartment(dept),
                      );
                    },
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: departments.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 156,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final dept = departments[index];
                      return _DepartmentCard(
                        department: dept,
                        onAddAdmin: () => _openDepartmentAdminDialog(dept),
                        onEditAdmin: (UserModel adminUser) => _openEditDepartmentAdmin(dept, adminUser),
                        onRemoveAdmin: (String adminUserId, String adminName) =>
                            _removeDepartmentAdmin(
                          dept,
                          adminUserId: adminUserId,
                          adminName: adminName,
                        ),
                        onDelete: () => _deleteDepartment(dept),
                      );
                    },
                  );

        final Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (isMobile)
              title
            else
              ResponsiveWrapToolbar(
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  title,
                  addDepartmentButton,
                ],
              ),
            const SizedBox(height: 12),
            departmentList,
          ],
        );

        if (isMobile) {
          return Stack(
            children: <Widget>[
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: MobileCreateFabStyles.listBottomPadding),
                child: body,
              ),
              MobileCreateFab(
                onPressed: _showAddDepartmentDialog,
                tooltip: 'Add Department',
              ),
            ],
          );
        }

        return SingleChildScrollView(child: body);
      },
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.onAddAdmin,
    required this.onEditAdmin,
    required this.onRemoveAdmin,
    required this.onDelete,
  });

  final Map<String, dynamic> department;
  final VoidCallback onAddAdmin;
  final void Function(UserModel adminUser) onEditAdmin;
  final void Function(String adminUserId, String adminName) onRemoveAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String name = (department['name'] as String?) ?? '-';
    final String admin = (department['departmentAdmin'] as String?)?.trim().isNotEmpty == true
        ? (department['departmentAdmin'] as String).trim()
        : '';
    final String adminUserId = ((department['adminUserId'] as String?) ?? '').trim();
    final UserModel? adminUser = department['adminUser'] as UserModel?;
    final String departmentId = ((department['id'] as String?) ?? '').trim();
    final int teamMemberCount = (department['teamMemberCount'] as int?) ?? 0;
    final int judgeCount = (department['judgeCount'] as int?) ?? 0;
    final int coordinatorCount = (department['coordinatorCount'] as int?) ?? 0;
    final bool hasAdmin = adminUserId.isNotEmpty && admin.isNotEmpty && admin != '-';
    final UserModel adminIdentity = adminUser ??
        UserModel(
          userId: adminUserId,
          phone: '',
          firstName: admin,
          lastName: '',
          email: '',
          role: 'DADM',
          orgType: null,
          orgId: '',
          department: name,
          departmentCode: '',
          status: UserStatus.active,
          createdAt: DateTime.now(),
        );

    return Container(
      decoration: kDashboardCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DashboardCardTitleBand(
            title: name,
            leading: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8ECF8)),
              ),
              child: const Icon(AppIcons.departments, size: 17, color: Color(0xFF6A38FF)),
            ),
            trailing: departmentId.isEmpty
                ? null
                : HoverIconActionButton(
                    icon: AppIcons.delete,
                    tooltip: 'Delete department',
                    destructive: true,
                    iconSize: 17,
                    onTap: onDelete,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text(
                      'Department admin',
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
                        user: adminIdentity,
                        radius: 12,
                        ringPadding: 2,
                        onTap: () => WorkspaceNavigator.openUser(context, adminUserId),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          admin,
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
                      HoverIconActionButton(
                        icon: AppIcons.edit,
                        tooltip: 'Edit department admin',
                        onTap: () => onEditAdmin(adminUser ?? adminIdentity),
                      ),
                      HoverIconActionButton(
                        icon: AppIcons.delete,
                        tooltip: 'Remove department admin',
                        destructive: true,
                        onTap: () => onRemoveAdmin(adminUserId, admin),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: onAddAdmin,
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
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    CountPill.teamMembers(teamMemberCount),
                    CountPill.judges(judgeCount),
                    CountPill.coordinators(coordinatorCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

