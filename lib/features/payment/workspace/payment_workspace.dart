import 'package:flutter/material.dart';

import 'package:hackz/features/idea/workspace/idea_workspace.dart';
import 'package:hackz/features/team/workspace/team_workspace.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/features/user/workspace/user_workspace.dart';
import 'package:hackz/core/workspace/workspace_host.dart';
import 'package:hackz/core/workspace/workspace_route.dart';
import 'payment_workspace_body.dart';
import 'payment_workspace_loader.dart';

/// Read-only payment audit workspace.
abstract final class PaymentWorkspace {
  static WorkspaceRoute _route(String id, {UserModel? actor}) {
    late PaymentWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'payment:$id',
      title: 'Payment Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'payment-verification',
      actor: actor,
      prepare: () async {
        vm = await PaymentWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => PaymentWorkspaceBody(vm: vm),
    );
  }

  static void open(BuildContext context, String paymentId, {UserModel? actor}) {
    final String id = paymentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'payment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void push(BuildContext context, String paymentId, {UserModel? actor}) {
    final String id = paymentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'payment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }

  static void openIdeaFromPayment(BuildContext context, PaymentWorkspaceViewModel vm, {UserModel? actor}) {
    final String id = vm.payment.ideaId.trim();
    if (id.isEmpty) return;
    IdeaWorkspace.push(context, id, actor: actor);
  }

  static void openTeamFromPayment(BuildContext context, PaymentWorkspaceViewModel vm, {UserModel? actor}) {
    final String id = vm.payment.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id, actor: actor);
  }

  static void openUserFromPayment(BuildContext context, PaymentWorkspaceViewModel vm, {UserModel? actor}) {
    final String id = vm.payment.paidByStudentId.trim();
    if (id.isEmpty) return;
    UserWorkspace.push(context, id, actor: actor);
  }
}
