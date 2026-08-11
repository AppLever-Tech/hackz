import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../evaluations/screens/evaluation_results_screen.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_service.dart';

/// Opens the **existing** Evaluation Results UX scoped to one Ideathon.
///
/// Does not create a second results screen — embeds [EvaluationResultsScreen].
abstract final class IdeathonResultsWorkspace {
  IdeathonResultsWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {required UserModel actor}) {
    String name = '';
    return WorkspaceRoute(
      id: 'ideathonResults:$ideathonId',
      title: 'Ideathon Evaluation Results',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      prepare: () async {
        final ideathon = await IdeathonService.fetchById(ideathonId);
        if (ideathon == null) throw StateError('Ideathon not found.');
        name = ideathon.name;
      },
      builder: (BuildContext context) {
        return EvaluationResultsScreen(
          user: actor,
          ideathonId: ideathonId,
          ideathonName: name,
        );
      },
    );
  }

  static void open(
    BuildContext context,
    String ideathonId, {
    required UserModel actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonResults:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void push(
    BuildContext context,
    String ideathonId, {
    required UserModel actor,
  }) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    final String routeId = 'ideathonResults:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
