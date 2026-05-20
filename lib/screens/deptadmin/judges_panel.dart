import 'package:flutter/material.dart';

import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../models/department_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../workspace/workspace.dart';
import '../common/create_user_dialog.dart';
import '../common/dashboard_components.dart';

class JudgesPanelScreen extends StatefulWidget {
  const JudgesPanelScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<JudgesPanelScreen> createState() => _JudgesPanelScreenState();
}

class _JudgesPanelScreenState extends State<JudgesPanelScreen> {
  OrganizationModel get _organization => OrganizationModel(
        id: widget.user.orgId,
        name: '',
        type: widget.user.orgType ?? OrganizationType.college,
        address: '',
        website: '',
        contact: '',
        createdAt: DateTime.now(),
      );

  Future<void> _addJudge() async {
    final changed = await showCreateUserDialog(
      context: context,
      roleCode: 'JUD',
      organization: _organization,
      department: widget.user.department,
      onUserSaved: (savedUser) async {
        await FirestoreUtils.updateUser(savedUser.userId, <String, dynamic>{
          'role': 'JUD',
          'orgId': widget.user.orgId,
          'department': widget.user.department,
          'departmentCode': DepartmentModel.resolveCode(widget.user.departmentCode),
        });
      },
    );
    if (changed && mounted) setState(() {});
  }

  Future<void> _removeJudge(UserModel user) async {
    await FirestoreUtils.deleteUser(user.userId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: FirestoreUtils.getDepartmentUsers(
        orgId: widget.user.orgId,
        department: widget.user.departmentCode,
        roleCodes: const <String>['JUD'],
      ),
      builder: (BuildContext context, AsyncSnapshot<List<UserModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load judges panel: ${snapshot.error}');
        }
        final judges = snapshot.data ?? <UserModel>[];
        return SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Judges Panel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addJudge,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Judge'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (judges.isEmpty)
                const Text('No judges assigned for this department.')
              else
                ...judges.map(
                  (judge) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: InkWell(
                      onTap: () => WorkspaceNavigator.openUser(context, judge.userId),
                      child: Text(
                        '${judge.firstName} ${judge.lastName}'.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    subtitle: Text('${judge.email} | ${judge.phone}'),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _removeJudge(judge),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
