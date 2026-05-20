import 'package:flutter/material.dart';

import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../evaluation/evaluation_workspace.dart';
import '../payment/payment_workspace.dart';
import '../problem/problem_workspace.dart';
import '../team/team_workspace.dart';
import 'idea_workspace_body.dart';
import 'idea_workspace_loader.dart';

/// Read-only innovation proposal workspace for a Hackz idea.
abstract final class IdeaWorkspace {
  static WorkspaceRoute _route(String id) {
    late IdeaWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'idea:$id',
      title: 'Idea Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await IdeaWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => IdeaWorkspaceBody(vm: vm),
    );
  }

  /// Opens the idea workspace (replaces the current workspace stack).
  static void open(BuildContext context, String ideaId) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  /// Pushes the idea workspace on top of the current route.
  static void push(BuildContext context, String ideaId) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }

  static void openProblemFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String id = vm.problem.problemId.trim().isEmpty ? vm.idea.problemId.trim() : vm.problem.problemId.trim();
    if (id.isEmpty) return;
    ProblemWorkspace.push(context, id);
  }

  static void openTeamFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String id = vm.team.teamId.trim().isEmpty ? vm.idea.teamId.trim() : vm.team.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id);
  }

  static void openPaymentFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String paymentId = vm.payment?.paymentId.trim() ?? '';
    if (paymentId.isEmpty) return;
    PaymentWorkspace.push(context, paymentId);
  }

  static void openEvaluationFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    if (vm.scores.isEmpty) return;
    EvaluationWorkspace.push(context, vm.idea.ideaId);
  }
}
