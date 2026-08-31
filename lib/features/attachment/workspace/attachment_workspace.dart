import 'package:flutter/material.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/idea/workspace/idea_workspace.dart';
import 'package:hackz/features/payment/workspace/payment_workspace.dart';
import 'package:hackz/features/problems/workspace/problem_workspace.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/workspace/workspace_host.dart';
import 'package:hackz/core/workspace/workspace_route.dart';
import 'attachment_workspace_body.dart';
import 'attachment_workspace_loader.dart';

/// Read-only attachment viewing workspace.
abstract final class AttachmentWorkspace {
  static WorkspaceRoute _route(String id, {UserModel? actor}) {
    late AttachmentWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'attachment:$id',
      title: 'Attachment Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      actor: actor,
      prepare: () async {
        vm = await AttachmentWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => AttachmentWorkspaceBody(vm: vm),
    );
  }

  static void open(BuildContext context, String attachmentId, {UserModel? actor}) {
    final String id = attachmentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'attachment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void push(BuildContext context, String attachmentId, {UserModel? actor}) {
    final String id = attachmentId.trim();
    if (id.isEmpty) return;
    final String routeId = 'attachment:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }

  static void openRelated(BuildContext context, AttachmentRelatedEntity related, {UserModel? actor}) {
    final String id = related.entityId.trim();
    if (id.isEmpty) return;
    switch (related.entityType) {
      case AttachmentEntityType.idea:
        IdeaWorkspace.push(context, id, actor: actor);
      case AttachmentEntityType.problem:
        ProblemWorkspace.push(context, id, actor: actor);
      case AttachmentEntityType.payment:
        PaymentWorkspace.push(context, id, actor: actor);
      case AttachmentEntityType.organization:
      case AttachmentEntityType.feedback:
        break;
    }
  }

  /// Opens workspace for an attachment model (convenience).
  static void openModel(BuildContext context, AttachmentModel attachment, {UserModel? actor}) {
    push(context, attachment.attachmentId, actor: actor);
  }
}
