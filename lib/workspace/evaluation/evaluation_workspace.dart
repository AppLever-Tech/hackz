import 'package:flutter/material.dart';

import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../idea/idea_workspace.dart';
import '../../features/team/workspace/team_workspace.dart';
import '../user/user_workspace.dart';
import 'evaluation_workspace_body.dart';
import 'evaluation_workspace_loader.dart';

/// Read-only evaluation report workspace (scoring + feedback).
abstract final class EvaluationWorkspace {
  static WorkspaceRoute _route(String id) {
    late EvaluationWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'evaluation:$id',
      title: 'Evaluation Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await EvaluationWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => EvaluationWorkspaceBody(vm: vm),
    );
  }

  static void open(BuildContext context, String evaluationId) {
    final String id = evaluationId.trim();
    if (id.isEmpty) return;
    final String routeId = 'evaluation:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  static void push(BuildContext context, String evaluationId) {
    final String id = evaluationId.trim();
    if (id.isEmpty) return;
    final String routeId = 'evaluation:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }

  static void openIdeaFromEvaluation(BuildContext context, EvaluationWorkspaceViewModel vm) {
    final String id = vm.idea.ideaId.trim();
    if (id.isEmpty) return;
    IdeaWorkspace.push(context, id);
  }

  static void openTeamFromEvaluation(BuildContext context, EvaluationWorkspaceViewModel vm) {
    final String id = vm.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id);
  }

  static void openUserFromEvaluation(BuildContext context, String judgeId) {
    final String id = judgeId.trim();
    if (id.isEmpty) return;
    UserWorkspace.push(context, id);
  }
}
