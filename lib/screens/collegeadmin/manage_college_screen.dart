import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/department_model.dart';
import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../common/app_dialog_template.dart';
import '../common/create_user_dialog.dart';
import '../common/dashboard_components.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/responsive_alert_dialog.dart';
import '../../widgets/responsive/responsive_filter_bar.dart';
import '../../workspace/workspace.dart';

class ManageCollegeScreen extends StatefulWidget {
  const ManageCollegeScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ManageCollegeScreen> createState() => _ManageCollegeScreenState();
}

class _ManageCollegeScreenState extends State<ManageCollegeScreen> {
  OrganizationModel get _organization => OrganizationModel(
        id: widget.user.orgId,
        name: '',
        type: widget.user.orgType ?? OrganizationType.college,
        address: '',
        website: '',
        contact: '',
        createdAt: DateTime.now(),
      );

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
    if (mounted && changed) setState(() {});
  }

  Future<void> _removeDepartmentAdmin(
    Map<String, dynamic> dept, {
    required String adminUserId,
    required String adminName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveAlertDialog(
          title: const Text('Remove department admin?'),
          widthPreset: DialogWidthPreset.compact,
          content: Text('Remove $adminName from this department?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final departmentId = ((dept['id'] as String?) ?? '').trim();
    if (departmentId.isEmpty || adminUserId.trim().isEmpty) return;
    await FirestoreUtils.clearDepartmentAdmin(departmentId: departmentId);
    await FirestoreUtils.updateUser(adminUserId, <String, dynamic>{
      'role': 'FAC',
      'department': '',
      'departmentCode': '',
    });
    if (mounted) setState(() {});
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final String departmentId = ((dept['id'] as String?) ?? '').trim();
    final String name = ((dept['name'] as String?) ?? 'this department').trim();
    if (departmentId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This department cannot be deleted because it has no department record.'),
        ),
      );
      return;
    }

    final int facultyCount = (dept['facultyCount'] as int?) ?? 0;
    final int studentCount = (dept['studentCount'] as int?) ?? 0;
    final String adminUserId = ((dept['adminUserId'] as String?) ?? '').trim();
    final bool hasUsers = facultyCount > 0 || studentCount > 0;
    final bool hasAdmin = adminUserId.isNotEmpty;

    final StringBuffer warning = StringBuffer('Delete "$name"?');
    if (hasUsers || hasAdmin) {
      warning.write('\n\nThis removes the department record from your college.');
      final List<String> parts = <String>[];
      if (facultyCount > 0) parts.add('$facultyCount faculty');
      if (studentCount > 0) parts.add('$studentCount students');
      if (hasAdmin) parts.add('the assigned department admin');
      if (parts.isNotEmpty) {
        warning.write(' ${parts.join(', ')} will remain in the college but are no longer tied to this department entry.');
      }
    }
    warning.write('\n\nThis cannot be undone.');

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveAlertDialog(
          title: const Text('Delete department?'),
          widthPreset: DialogWidthPreset.compact,
          content: Text(warning.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      if (hasAdmin) {
        await FirestoreUtils.clearDepartmentAdmin(departmentId: departmentId);
        await FirestoreUtils.updateUser(adminUserId, <String, dynamic>{
          'role': 'FAC',
          'department': '',
          'departmentCode': '',
        });
      }
      await FirestoreUtils.deleteDepartment(departmentId: departmentId);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete department: $e')),
      );
    }
  }

  Future<void> _showAddDepartmentDialog() async {
    final departmentController = TextEditingController();
    final customDepartmentController = TextEditingController();
    String selectedDepartment = '';
    bool useCustomDepartment = false;
    bool isSaving = false;

    final shouldRefresh = await showAppDialog<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
            Future<void> submit() async {
              final departmentName = useCustomDepartment
                  ? customDepartmentController.text.trim()
                  : selectedDepartment.trim();
              if (departmentName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select or enter a department')),
                );
                return;
              }

              final departmentCode = _resolveDepartmentCode(departmentName);
              setState(() => isSaving = true);
              var didPop = false;
              try {
                await FirestoreUtils.addDepartment(
                  orgId: widget.user.orgId,
                  name: departmentName,
                  code: departmentCode,
                );
                if (!context.mounted) return;
                didPop = true;
                Navigator.of(context).pop(true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not add department: $e')),
                  );
                }
              } finally {
                // Do not rebuild after pop — DropdownMenu can still touch the controller during route teardown.
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
                        decoration: const InputDecoration(
                          hintText: 'Enter department name',
                          prefixIcon: Icon(AppIcons.departments),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!isSaving) submit();
                        },
                      )
                    else
                      DropdownMenu<String>(
                        width: MediaQuery.sizeOf(context).width * 0.9,
                        requestFocusOnTap: true,
                        controller: departmentController,
                        hintText: 'Select department',
                        enableSearch: true,
                        dropdownMenuEntries: DepartmentModel.masterNames
                            .map(
                              (name) => DropdownMenuEntry<String>(
                                value: name,
                                label: name,
                              ),
                            )
                            .toList(growable: false),
                        onSelected: (value) {
                          setState(() => selectedDepartment = value ?? '');
                        },
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
    // Let the dialog route (and DropdownMenu overlays) finish disposing before releasing controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      departmentController.dispose();
      customDepartmentController.dispose();
    });
    if (mounted && shouldRefresh == true) setState(() {});
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
      future: FirestoreUtils.getDepartmentsByCollege(widget.user.orgId),
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

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ResponsiveWrapToolbar(
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Departments ($deptCount)',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddDepartmentDialog,
                    icon: const Icon(AppIcons.add),
                    label: const Text('Add Department'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (departments.isEmpty)
                Text(
                  'No departments available for this college.',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
              else if (isMobile)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: departments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (BuildContext context, int index) {
                    final dept = departments[index];
                    return _DepartmentCard(
                      department: dept,
                      onAddAdmin: () => _openDepartmentAdminDialog(dept),
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
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: departments.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 148,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final dept = departments[index];
                    return _DepartmentCard(
                      department: dept,
                      onAddAdmin: () => _openDepartmentAdminDialog(dept),
                      onRemoveAdmin: (String adminUserId, String adminName) =>
                          _removeDepartmentAdmin(
                        dept,
                        adminUserId: adminUserId,
                        adminName: adminName,
                      ),
                      onDelete: () => _deleteDepartment(dept),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.onAddAdmin,
    required this.onRemoveAdmin,
    required this.onDelete,
  });

  final Map<String, dynamic> department;
  final VoidCallback onAddAdmin;
  final void Function(String adminUserId, String adminName) onRemoveAdmin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String name = (department['name'] as String?) ?? '-';
    final String admin = (department['departmentAdmin'] as String?)?.trim().isNotEmpty == true
        ? (department['departmentAdmin'] as String).trim()
        : '';
    final String adminUserId = ((department['adminUserId'] as String?) ?? '').trim();
    final String departmentId = ((department['id'] as String?) ?? '').trim();
    final int facultyCount = (department['facultyCount'] as int?) ?? 0;
    final int studentCount = (department['studentCount'] as int?) ?? 0;
    final bool hasAdmin = adminUserId.isNotEmpty && admin.isNotEmpty && admin != '-';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.15),
                ),
              ),
              if (departmentId.isNotEmpty)
                Tooltip(
                  message: 'Delete department',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(AppIcons.remove, size: 17, color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasAdmin)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: ContextPill(
                    label: admin,
                    semantic: ContextPillSemantic.user,
                    icon: AppIcons.adminProfile,
                    onTap: () => WorkspaceNavigator.openUser(context, adminUserId),
                    compact: true,
                  ),
                ),
                const SizedBox(width: 2),
                Tooltip(
                  message: 'Remove department admin',
                  child: InkWell(
                    onTap: () => onRemoveAdmin(adminUserId, admin),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(AppIcons.remove, size: 15, color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: onAddAdmin,
              icon: const Icon(AppIcons.add, size: 15),
              label: const Text('Add Department admin'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(height: 6),
          _DepartmentCountsChip(
            facultyCount: facultyCount,
            studentCount: studentCount,
          ),
        ],
      ),
    );
  }
}

/// Single-line chip: faculty and student counts with icon, label, and bold count.
class _DepartmentCountsChip extends StatelessWidget {
  const _DepartmentCountsChip({
    required this.facultyCount,
    required this.studentCount,
  });

  final int facultyCount;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9E2F5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DepartmentCountSegment(
            icon: AppIcons.faculty,
            label: 'Faculty',
            count: facultyCount,
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFE2E8F0),
          ),
          _DepartmentCountSegment(
            icon: AppIcons.student,
            label: 'Students',
            count: studentCount,
          ),
        ],
      ),
    );
  }
}

class _DepartmentCountSegment extends StatelessWidget {
  const _DepartmentCountSegment({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF57629A)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1,
          ),
        ),
      ],
    );
  }
}
