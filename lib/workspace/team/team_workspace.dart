import 'package:flutter/material.dart';

import '../../models/idea_model.dart';
import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../user/user_workspace.dart';
import 'team_ideas_section.dart';
import 'team_workspace_body.dart';
import 'team_workspace_loader.dart';

/// Read-only contextual workspace for a Hackz innovation team.
abstract final class TeamWorkspace {
  static WorkspaceRoute _route(String id) {
    late TeamWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'team:$id',
      title: 'Team',
      subtitle: 'Loading…',
      prepare: () async {
        vm = await TeamWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => TeamWorkspaceBody(vm: vm),
    );
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

  /// Pushes a lightweight idea preview on top of the team workspace.
  static void openIdeaFromTeam(BuildContext context, TeamIdeaPreview preview) {
    final String ideaId = preview.idea.ideaId.trim();
    if (ideaId.isEmpty) return;
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == 'idea:$ideaId') return;
    HkzWorkspace.push(
      context,
      WorkspaceRoute(
        id: 'idea:$ideaId',
        title: preview.idea.ideaTitle.trim().isEmpty ? 'Idea' : preview.idea.ideaTitle.trim(),
        subtitle: _ideaStatusLabel(preview.idea.status),
        builder: (BuildContext context) => TeamIdeaPreviewRoute(
          preview: preview,
          onOpenCreator: preview.createdByUserId.trim().isEmpty
              ? null
              : () => openUserFromTeam(context, preview.createdByUserId),
        ),
      ),
    );
  }
}

String _ideaStatusLabel(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.pendingSubmission => 'Pending',
    IdeaStatus.submitted => 'Submitted',
    IdeaStatus.underReview => 'Under review',
    IdeaStatus.evaluated => 'Evaluated',
    IdeaStatus.approved => 'Approved',
    IdeaStatus.rejected => 'Rejected',
  };
}
