import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_judge_assignment_service.dart';
import 'ideathon_judge_assignment_workspace_body.dart';

/// Department Admin workspace for Ideathon-scoped judge assignment.
abstract final class IdeathonJudgeAssignmentWorkspace {
  IdeathonJudgeAssignmentWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {UserModel? actor}) {
    late IdeathonJudgeAssignmentViewModel vm;
    return WorkspaceRoute(
      id: 'ideathonJudgeAssignment:$ideathonId',
      title: 'Ideathon Judge Assignment',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      prepare: () async {
        vm = await IdeathonJudgeAssignmentService.load(ideathonId);
      },
      builder: (BuildContext context) => IdeathonJudgeAssignmentWorkspaceBody(
        vm: vm,
        actor: actor,
      ),
    );
  }

  static void open(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonJudgeAssignment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void push(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonJudgeAssignment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
