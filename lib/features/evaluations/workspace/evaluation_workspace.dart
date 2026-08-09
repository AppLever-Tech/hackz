import 'package:flutter/material.dart';

import '../models/evaluation_details_view_model.dart';
import '../services/evaluation_details_loader.dart';
import 'evaluation_details_workspace.dart';
import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';

/// Read-only evaluation report workspace (evaluation-centric).
abstract final class EvaluationWorkspace {
  static WorkspaceRoute _route(String id) {
    late EvaluationDetailsViewModel vm;
    return WorkspaceRoute(
      id: 'evaluation:$id',
      title: 'Evaluation Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'evaluation-lifecycle',
      prepare: () async {
        vm = await EvaluationDetailsLoader.load(ideaId: id);
      },
      builder: (BuildContext context) => EvaluationDetailsBody(
        vm: vm,
        layout: EvaluationDetailsLayout.workspace,
      ),
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
}
