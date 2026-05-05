import 'package:flutter/material.dart';

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
    String selectedDepartment = '';
    bool isSaving = false;

    final shouldRefresh = await showAppDialog<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
            Future<void> submit() async {
              if (selectedDepartment.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a department')),
                );
                return;
              }

              final departmentCode = DepartmentModel.byName(selectedDepartment)?.code ?? '';
              setState(() => isSaving = true);
              try {
                await FirestoreUtils.addDepartment(
                  orgId: widget.user.orgId,
                  name: selectedDepartment,
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
                        Icon(Icons.account_tree_outlined, color: Color(0xFF6A38FF), size: 28),
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
                    const Text(
                      'Department',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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
    if (mounted && shouldRefresh == true) setState(() {});
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
                      'Manage College',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddDepartmentDialog,
                    icon: const Icon(Icons.add),
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
                    childAspectRatio: 3.2,
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
    final code = (department['code'] as String?) ?? '-';
    final admin = (department['departmentAdmin'] as String?)?.trim().isNotEmpty == true
        ? (department['departmentAdmin'] as String).trim()
        : 'Not Assigned';
    final adminUserId = ((department['adminUserId'] as String?) ?? '').trim();
    final facultyCount = (department['facultyCount'] as int?) ?? 0;
    final studentCount = (department['studentCount'] as int?) ?? 0;
    final totalIdeas = (department['totalIdeas'] as int?) ?? 0;
    final hasAdmin = adminUserId.isNotEmpty && admin != 'Not Assigned';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
          Text(
            code,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (!hasAdmin)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'No Department Admin',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add Admin',
                  onPressed: onAddAdmin,
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF6A38FF)),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'No admin to remove',
                  onPressed: null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                CircleAvatar(
                radius: 14,
                  backgroundColor: const Color(0xFFE9EEFF),
                  child: Text(
                    admin.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF42508B)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    admin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove Admin',
                  onPressed: () => onRemoveAdmin(adminUserId, admin),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          const SizedBox(height: 0),
          Text(
            'Faculty: $facultyCount   Student: $studentCount   Ideas: $totalIdeas',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
