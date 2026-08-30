import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import '../screens/tabs/ideathon_payments_tab.dart';
import '../services/ideathon_service.dart';

/// Stacks Event Payments (Event Details Payments tab) in the right-side workspace.
abstract final class IdeathonPaymentWorkspace {
  IdeathonPaymentWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {UserModel? actor}) {
    return WorkspaceRoute(
      id: 'ideathonPayments:$ideathonId',
      title: 'Event Payments',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      prepare: () async {
        final ideathon = await IdeathonService.fetchById(ideathonId);
        if (ideathon == null) throw StateError('Ideathon not found.');
      },
      builder: (BuildContext context) => IdeathonPaymentsTab(
        ideathonId: ideathonId,
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
