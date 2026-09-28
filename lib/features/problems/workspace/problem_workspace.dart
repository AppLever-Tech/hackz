import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../idea/workspace/idea_workspace.dart';
import '../../user/models/user_model.dart';
import '../../user/workspace/user_workspace.dart';
import 'problem_workspace_body.dart';
import 'problem_workspace_loader.dart';

export 'problem_workspace_loader.dart';

/// Read-only contextual workspace for a Hackz problem.
abstract final class ProblemWorkspace {
  static WorkspaceRoute _route(String id, {UserModel? actor}) {
    late ProblemWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'problem:$id',
      title: 'Problem Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'problem-lifecycle',
      actor: actor,
      prepare: () async {
        vm = await ProblemWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => ProblemWorkspaceBody(vm: vm),
    );
  }

  static void push(BuildContext context, String problemId, {UserModel? actor}) {
    final String id = problemId.trim();
    if (id.isEmpty) return;
    final String routeId = 'problem:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }

  static void open(BuildContext context, String problemId, {UserModel? actor}) {
    final String id = problemId.trim();
    if (id.isEmpty) return;
    final String routeId = 'problem:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void openUserFromProblem(BuildContext context, String userId, {UserModel? actor}) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == 'user:$id') return;
    UserWorkspace.push(context, id, actor: actor);
  }

  static void openIdeaFromProblem(BuildContext context, ProblemIdeaPreview preview, {UserModel? actor}) {
    IdeaWorkspace.push(context, preview.idea.ideaId, actor: actor);
  }
}
