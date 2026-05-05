import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/enums/user_role.dart';
import '../../models/enums/user_status.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';

class PendingUsersScreen extends StatelessWidget {
  const PendingUsersScreen({super.key, required this.currentUser});

  final UserModel currentUser;

  Future<String?> _selectRoleForApproval(BuildContext context) async {
    String selected = 'STU';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select Role'),
          content: DropdownButtonFormField<String>(
            value: selected,
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
              setState(() => selected = value);
            },
          ),
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveUser(BuildContext context, UserModel user) async {
    final role = await _selectRoleForApproval(context);
    if (role == null) return;
    await FirestoreUtils.updateUser(
      user.userId,
      <String, dynamic>{
        'role': role,
        'status': UserStatus.active.value,
        'approvedBy': currentUser.userId,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'rejectionReason': null,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved ${user.firstName} ${user.lastName}')),
    );
  }

  Future<void> _rejectUser(BuildContext context, UserModel user) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject user'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(reasonController.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null) return;
    await FirestoreUtils.updateUser(
      user.userId,
      <String, dynamic>{
        'status': UserStatus.rejected.value,
        'approvedBy': currentUser.userId,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'rejectionReason': reason.isEmpty ? null : reason,
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected ${user.firstName} ${user.lastName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(currentUser.role) != UserRole.departmentAdmin) {
      return const Center(child: Text('Access denied: Department Admin only'));
    }
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreUtils.watchPendingUsers(
        orgId: currentUser.orgId,
        departmentCode: currentUser.departmentCode,
      ),
      builder: (BuildContext context, AsyncSnapshot<List<UserModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? <UserModel>[];
        if (users.isEmpty) {
          return const Center(child: Text('No pending users.'));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (BuildContext context, int index) {
            final user = users[index];
            return ListTile(
              title: Text('${user.firstName} ${user.lastName}'),
              subtitle: Text(user.phone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveUser(context, user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectUser(context, user),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
