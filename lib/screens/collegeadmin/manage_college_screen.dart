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
        return AlertDialog(
          title: const Text('Remove department admin?'),
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
              try {
                await FirestoreUtils.addDepartment(
                  orgId: widget.user.orgId,
                  name: departmentName,
                  code: departmentCode,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              } finally {
                if (context.mounted) {
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
                        width: 520,
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
    departmentController.dispose();
    customDepartmentController.dispose();
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
        return SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Departments',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
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
                const Text('No departments available for this college.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: departments.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 3.35,
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
  });

  final Map<String, dynamic> department;
  final VoidCallback onAddAdmin;
  final void Function(String adminUserId, String adminName) onRemoveAdmin;

  @override
  Widget build(BuildContext context) {
    final name = (department['name'] as String?) ?? '-';
    final admin = (department['departmentAdmin'] as String?)?.trim().isNotEmpty == true
        ? (department['departmentAdmin'] as String).trim()
        : 'Not Assigned';
    final adminUserId = ((department['adminUserId'] as String?) ?? '').trim();
    final facultyCount = (department['facultyCount'] as int?) ?? 0;
    final studentCount = (department['studentCount'] as int?) ?? 0;
    final totalIdeas = (department['totalIdeas'] as int?) ?? 0;
    final hasAdmin = adminUserId.isNotEmpty && admin != 'Not Assigned';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECF8)),
                ),
                child: const Tooltip(
                  message: 'Department',
                  child: Icon(AppIcons.departments, size: 20, color: Color(0xFF6A38FF)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: hasAdmin
                    ? Row(
                        children: <Widget>[
                          const Tooltip(
                            message: 'Department admin',
                            child: Icon(AppIcons.adminProfile, size: 17, color: Color(0xFF57629A)),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              admin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove department admin',
                            onPressed: () => onRemoveAdmin(adminUserId, admin),
                            icon: const Icon(AppIcons.remove, size: 15, color: Colors.redAccent),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          const Tooltip(
                            message: 'Department admin',
                            child: Icon(AppIcons.adminProfile, size: 17, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'No admin assigned',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add department admin',
                            onPressed: onAddAdmin,
                            icon: const Icon(AppIcons.add, size: 18, color: Color(0xFF6A38FF)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  _DepartmentCountChip(
                    icon: AppIcons.faculty,
                    count: facultyCount,
                    tooltip: 'Faculty count',
                  ),
                  const SizedBox(width: 8),
                  _DepartmentCountChip(
                    icon: AppIcons.student,
                    count: studentCount,
                    tooltip: 'Student count',
                  ),
                  const SizedBox(width: 8),
                  _DepartmentCountChip(
                    icon: AppIcons.ideas,
                    count: totalIdeas,
                    tooltip: 'Ideas count',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentCountChip extends StatelessWidget {
  const _DepartmentCountChip({
    required this.icon,
    required this.count,
    required this.tooltip,
  });

  final IconData icon;
  final int count;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD9E2F5), width: 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17, color: const Color(0xFF57629A)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
