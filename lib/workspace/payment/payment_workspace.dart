import 'package:flutter/material.dart';

import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../idea/idea_workspace.dart';
import '../team/team_workspace.dart';
import '../user/user_workspace.dart';
import 'payment_workspace_body.dart';
import 'payment_workspace_loader.dart';

/// Read-only payment audit workspace.
abstract final class PaymentWorkspace {
  static WorkspaceRoute _route(String id) {
    late PaymentWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'payment:$id',
      title: 'Payment Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await PaymentWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => PaymentWorkspaceBody(vm: vm),
    );
  }

  static void open(BuildContext context, String paymentId) {
    final String id = paymentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'payment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  static void push(BuildContext context, String paymentId) {
    final String id = paymentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'payment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }

  static void openIdeaFromPayment(BuildContext context, PaymentWorkspaceViewModel vm) {
    final String id = vm.payment.ideaId.trim();
    if (id.isEmpty) return;
    IdeaWorkspace.push(context, id);
  }

  static void openTeamFromPayment(BuildContext context, PaymentWorkspaceViewModel vm) {
    final String id = vm.payment.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id);
  }

  static void openUserFromPayment(BuildContext context, PaymentWorkspaceViewModel vm) {
    final String id = vm.payment.paidByStudentId.trim();
    if (id.isEmpty) return;
    UserWorkspace.push(context, id);
  }
}
