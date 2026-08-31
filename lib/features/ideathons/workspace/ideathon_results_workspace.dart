import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../events/models/event_kind.dart';
import '../../user/models/user_model.dart';
import 'ideathon_results_workspace_body.dart';
import 'ideathon_results_workspace_loader.dart';

/// Event-scoped evaluation results in the right-side workspace (Ideathon today; Hackathon later).
abstract final class IdeathonResultsWorkspace {
  IdeathonResultsWorkspace._();

  static WorkspaceRoute _route(String ideathonId) {
    late IdeathonResultsWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'ideathonResults:$ideathonId',
      title: 'Evaluation Results',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: EventKind.ideathon.helpPageId,
      prepare: () async {
        vm = await IdeathonResultsWorkspaceLoader.load(ideathonId);
      },
      builder: (BuildContext context) => IdeathonResultsWorkspaceBody(vm: vm),
    );
  }

  static void open(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonResults:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  static void push(
    BuildContext context,
    String ideathonId, {
    UserModel? actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonResults:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }
}
