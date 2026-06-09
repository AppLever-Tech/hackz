import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../idea/workspace/idea_workspace.dart';
import '../../user/workspace/user_workspace.dart';
import 'team_workspace_body.dart';
import 'team_workspace_loader.dart';

/// Read-only contextual workspace for a Hackz innovation team.
abstract final class TeamWorkspace {
  static WorkspaceRoute _route(String id) {
    late TeamWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'team:$id',
      title: 'Team Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await TeamWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => TeamWorkspaceBody(vm: vm),
    );
  }

  /// Pushes the team workspace on top of the current route.
  static void push(BuildContext context, String teamId) {
    final String id = teamId.trim();
    if (id.isEmpty) return;
    final String routeId = 'team:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }

  /// Opens the team workspace (replaces the current workspace stack).
  static void open(BuildContext context, String teamId) {
    final String id = teamId.trim();
    if (id.isEmpty) return;
    final String routeId = 'team:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  /// Pushes a user profile on top of the current workspace route.
  static void openUserFromTeam(BuildContext context, String userId) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == 'user:$id') return;
    UserWorkspace.push(context, id);
  }

  /// Pushes the full idea workspace on top of the team workspace.
  static void openIdeaFromTeam(BuildContext context, TeamIdeaPreview preview) {
    IdeaWorkspace.push(context, preview.idea.ideaId);
  }
}
