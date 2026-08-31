import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../ideathons/workspace/ideathon_workspace.dart';
import '../../problems/workspace/problem_workspace.dart';
import '../../team/workspace/team_workspace.dart';
import '../../user/models/user_model.dart';
import 'idea_workspace_body.dart';
import 'idea_workspace_loader.dart';

/// Read-only innovation proposal workspace for a Hackz idea.
abstract final class IdeaWorkspace {
  static WorkspaceRoute _route(String id, {UserModel? actor}) {
    late IdeaWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'idea:$id',
      title: 'Idea Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'idea-lifecycle',
      actor: actor,
      prepare: () async {
        vm = await IdeaWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => IdeaWorkspaceBody(vm: vm),
    );
  }

  /// Opens the idea workspace (replaces the current workspace stack).
  static void open(BuildContext context, String ideaId, {UserModel? actor}) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  /// Pushes the idea workspace on top of the current route.
  static void push(BuildContext context, String ideaId, {UserModel? actor}) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }

  static void openProblemFromIdea(BuildContext context, IdeaWorkspaceViewModel vm, {UserModel? actor}) {
    final String id = vm.problem.problemId.trim().isEmpty ? vm.idea.problemId.trim() : vm.problem.problemId.trim();
    if (id.isEmpty) return;
    ProblemWorkspace.push(context, id, actor: actor);
  }

  static void openTeamFromIdea(BuildContext context, IdeaWorkspaceViewModel vm, {UserModel? actor}) {
    final String id = vm.team.teamId.trim().isEmpty ? vm.idea.teamId.trim() : vm.team.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id, actor: actor);
  }

  static void openEvent(BuildContext context, String eventId, {UserModel? actor}) {
    final String id = eventId.trim();
    if (id.isEmpty) return;
    IdeathonWorkspace.push(context, id, actor: actor);
  }
}
