import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_theme.dart';
import 'user_activity_section.dart';
import 'user_metadata_section.dart';
import 'user_summary_section.dart';
import 'user_workspace_loader.dart';

class UserWorkspaceBody extends StatelessWidget {
  const UserWorkspaceBody({super.key, required this.vm});

  final UserWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        UserSummarySection(user: vm.user, organizationName: vm.organizationName),
        const SizedBox(height: 14),
        UserMetadataSection(user: vm.user),
        const SizedBox(height: 14),
        UserActivitySection(items: vm.recentActivity),
      ],
    );
  }
}
