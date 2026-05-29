import 'package:flutter/material.dart';

import '../../../models/organization_model.dart';
import '../models/user_model.dart';
import 'create_user_workspace.dart';

export 'create_user_workspace.dart' show showCreateUserWorkspace;

/// Backward-compatible entry point — opens the premium create/edit user workspace.
Future<bool> showCreateUserDialog({
  required BuildContext context,
  String? roleCode,
  List<String>? roleOptions,
  String? initialRoleCode,
  required OrganizationModel organization,
  String department = '',
  UserModel? initialUser,
  Future<void> Function(UserModel user)? onUserSaved,
}) {
  return showCreateUserWorkspace(
    context: context,
    roleCode: roleCode,
    roleOptions: roleOptions,
    initialRoleCode: initialRoleCode,
    organization: organization,
    department: department,
    initialUser: initialUser,
    onUserSaved: onUserSaved,
  );
}
