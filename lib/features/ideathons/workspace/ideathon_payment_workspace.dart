import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_payment_service.dart';
import 'ideathon_payment_workspace_body.dart';

/// Coordinator workspace for idea payments linked to Ideathon members.
abstract final class IdeathonPaymentWorkspace {
  IdeathonPaymentWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {UserModel? actor}) {
    late IdeathonPaymentWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'ideathonPayments:$ideathonId',
      title: 'Ideathon Payments',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      prepare: () async {
        vm = await IdeathonPaymentService.load(ideathonId);
      },
      builder: (BuildContext context) => IdeathonPaymentWorkspaceBody(
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
    final String routeId = 'ideathonPayments:$id';
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
    final String routeId = 'ideathonPayments:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
