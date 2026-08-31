import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../user/models/user_model.dart';
import 'ideathon_judge_assignment_workspace.dart';
import 'ideathon_payment_workspace.dart';
import 'ideathon_results_workspace.dart';
import 'ideathon_workspace_body.dart';
import 'ideathon_workspace_loader.dart';

abstract final class IdeathonWorkspace {
  IdeathonWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {UserModel? actor}) {
    late IdeathonWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'ideathon:$ideathonId',
      title: 'Ideathon',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      actor: actor,
      prepare: () async {
        vm = await IdeathonWorkspaceLoader.load(ideathonId);
      },
      builder: (BuildContext context) {
        final UserModel? viewer = HkzWorkspace.controllerOf(context).actor;
        return IdeathonWorkspaceBody(
          vm: vm,
          onOpenJudgeAssignment: () => IdeathonJudgeAssignmentWorkspace.push(
            context,
            ideathonId,
            actor: viewer,
          ),
          onOpenResults: () => IdeathonResultsWorkspace.push(
            context,
            ideathonId,
            actor: viewer,
          ),
          onOpenPayments: () => IdeathonPaymentWorkspace.push(
            context,
            ideathonId,
            actor: viewer,
          ),
        );
      },
    );
  }

  static void open(BuildContext context, String ideathonId, {UserModel? actor}) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    HkzWorkspace.open(context, _route(id, actor: actor));
  }

  static void push(BuildContext context, String ideathonId, {UserModel? actor}) {
    final String id = ideathonId.trim();
    if (id.isEmpty) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
