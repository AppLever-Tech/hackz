import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import 'user_workspace_body.dart';
import 'user_workspace_loader.dart';

/// Read-only contextual workspace for a Hackz user profile.
abstract final class UserWorkspace {
  static WorkspaceRoute _route(String id, {UserModel? actor}) {
    late UserWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'user:$id',
      title: 'User Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      actor: actor,
      prepare: () async {
        vm = await UserWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => UserWorkspaceBody(vm: vm),
    );
  }

  /// Opens the shared workspace with this user's summary (replaces any open workspace).
  /// [userId] is the profile being viewed. [actor] is who is looking.
  static void open(BuildContext context, String userId, {UserModel? actor}) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final String routeId = 'user:$id';

    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) {
      return;
    }
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  /// Pushes user profile on top of current workspace route.
  static void push(BuildContext context, String userId, {UserModel? actor}) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final String routeId = 'user:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
