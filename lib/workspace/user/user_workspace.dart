import 'package:flutter/material.dart';

import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import 'user_workspace_body.dart';
import 'user_workspace_loader.dart';

/// Read-only contextual workspace for a Hackz user profile.
abstract final class UserWorkspace {
  /// Opens the shared workspace with this user's summary (replaces any open workspace).
  static void open(BuildContext context, String userId) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final String routeId = 'user:$id';

    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) {
      return;
    }

    late UserWorkspaceViewModel vm;
    HkzWorkspace.open(
      context,
      WorkspaceRoute(
        id: routeId,
        title: 'Member',
        subtitle: 'Loading…',
        prepare: () async {
          vm = await UserWorkspaceLoader.load(id);
        },
        builder: (BuildContext context) => UserWorkspaceBody(vm: vm),
      ),
    );
  }
}
