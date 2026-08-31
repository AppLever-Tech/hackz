import 'package:flutter/material.dart';

import '../models/evaluation_details_view_model.dart';
import '../services/evaluation_details_loader.dart';
import 'evaluation_details_workspace.dart';
import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';

/// Read-only evaluation report workspace (evaluation-centric).
abstract final class EvaluationWorkspace {
  static WorkspaceRoute _route(String id, {String ideathonId = '', UserModel? actor}) {
    late EvaluationDetailsViewModel vm;
    final String eventId = ideathonId.trim();
    return WorkspaceRoute(
      id: eventId.isEmpty ? 'evaluation:$id' : 'evaluation:$id:$eventId',
      title: 'Evaluation Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'evaluation-lifecycle',
      actor: actor,
      prepare: () async {
        vm = await EvaluationDetailsLoader.load(ideaId: id, ideathonId: eventId);
      },
      builder: (BuildContext context) => EvaluationDetailsBody(
        vm: vm,
        layout: EvaluationDetailsLayout.workspace,
        actor: HkzWorkspace.controllerOf(context).actor,
      ),
    );
  }

  static void open(
    BuildContext context,
    String evaluationId, {
    String ideathonId = '',
    UserModel? actor,
  }) {
    final String id = evaluationId.trim();
    if (id.isEmpty) return;
    final WorkspaceRoute route = _route(id, ideathonId: ideathonId, actor: actor);
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == route.id) return;
    HkzWorkspace.open(context, route);
  }

  static void push(
    BuildContext context,
    String evaluationId, {
    String ideathonId = '',
    UserModel? actor,
  }) {
    final String id = evaluationId.trim();
    if (id.isEmpty) return;
    final WorkspaceRoute route = _route(id, ideathonId: ideathonId, actor: actor);
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == route.id) return;
    HkzWorkspace.push(context, route);
  }
}
