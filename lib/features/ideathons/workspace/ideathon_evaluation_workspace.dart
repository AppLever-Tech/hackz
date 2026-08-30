import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../evaluations/screens/judge_evaluation_workspace_screen.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_service.dart';

/// Opens the **existing** Judge Evaluation UX scoped to one Ideathon.
///
/// Does not create a second evaluation screen — embeds [JudgeEvaluationWorkspaceScreen].
abstract final class IdeathonEvaluationWorkspace {
  IdeathonEvaluationWorkspace._();

  static WorkspaceRoute _route(String ideathonId, {required UserModel actor}) {
    String name = '';
    return WorkspaceRoute(
      id: 'ideathonEvaluation:$ideathonId',
      title: 'Ideathon Evaluation',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'ideathon',
      prepare: () async {
        final ideathon = await IdeathonService.fetchById(ideathonId);
        if (ideathon == null) throw StateError('Ideathon not found.');
        name = ideathon.name;
      },
      builder: (BuildContext context) {
        if (UserRole.fromCode(actor.role) != UserRole.judge) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Ideathon evaluation is available to assigned Judges from their Scoring workspace, '
                'or open this view while signed in as a Judge.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
            ),
          );
        }
        return Padding(
          padding: WorkspaceTheme.bodyPadding(context),
          child: JudgeEvaluationWorkspaceScreen(
            user: actor,
            ideathonId: ideathonId,
            ideathonName: name,
          ),
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
    final String routeId = 'ideathonEvaluation:$id';
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
    final String routeId = 'ideathonEvaluation:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id, actor: actor));
  }
}
