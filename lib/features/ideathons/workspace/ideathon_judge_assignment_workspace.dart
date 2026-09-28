import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../events/models/event_kind.dart';
import '../../user/models/user_model.dart';
import 'ideathon_judge_assignment_workspace_body.dart';
import 'ideathon_judge_assignment_workspace_loader.dart';

/// Event-scoped judge assignment in the right-side workspace (Ideathon today; Hackathon later).
abstract final class IdeathonJudgeAssignmentWorkspace {
  IdeathonJudgeAssignmentWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {UserModel? actor}) {
    late IdeathonJudgeAssignmentWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'ideathonJudgeAssignment:$ideathonId',
      title: 'Judge Assignment',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: EventKind.ideathon.helpPageId,
      actor: actor,
      prepare: () async {
        vm = await IdeathonJudgeAssignmentWorkspaceLoader.load(ideathonId);
      },
      builder: (BuildContext context) => IdeathonJudgeAssignmentWorkspaceBody(
        vm: vm,
        actor: HkzWorkspace.controllerOf(context).actor,
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
