import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import 'evaluation_template_workspace_body.dart';
import 'evaluation_template_workspace_loader.dart';

/// Read-only evaluation template inspection workspace.
abstract final class EvaluationTemplateWorkspace {
  static WorkspaceRoute _route(String id, {String? departmentCode, UserModel? actor}) {
    late EvaluationTemplateWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'evaluationTemplate:$id',
      title: 'Evaluation Template',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'evaluation-lifecycle',
      actor: actor,
      prepare: () async {
        vm = await EvaluationTemplateWorkspaceLoader.load(
          id,
          departmentCode: departmentCode,
        );
      },
      builder: (BuildContext context) => EvaluationTemplateWorkspaceBody(vm: vm),
    );
  }

  /// Opens the template workspace (replaces the current workspace stack).
  static void open(
    BuildContext context,
    String templateId, {
    String? departmentCode,
    UserModel? actor,
  }) {
    final String id = templateId.trim();
    if (id.isEmpty) return;
    final String routeId = 'evaluationTemplate:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, departmentCode: departmentCode, actor: actor));
  }

  /// Pushes the template workspace on top of the current route.
  static void push(
    BuildContext context,
    String templateId, {
    String? departmentCode,
    UserModel? actor,
  }) {
    final String id = templateId.trim();
    if (id.isEmpty) return;
    final String routeId = 'evaluationTemplate:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, departmentCode: departmentCode, actor: actor));
  }
}
