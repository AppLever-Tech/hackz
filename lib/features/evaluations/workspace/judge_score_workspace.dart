import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_route.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../user/models/user_model.dart';
import 'judge_score_workspace_body.dart';
import 'judge_score_workspace_loader.dart';

/// Read-only judge scoring for one recorded score (Ideathon or Hackathon).
abstract final class JudgeScoreWorkspace {
  static WorkspaceRoute _route({
    required String scoreId,
    required IdeaModel idea,
    required String teamLabel,
    required String templateId,
    required String ideathonId,
    required String departmentCode,
    UserModel? judge,
    UserModel? actor,
  }) {
    late JudgeScoreWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'judgeScore:$scoreId',
      title: 'Judge Evaluation',
      subtitle: WorkspaceRoute.loadingSubtitle,
      helpPageId: 'evaluation-lifecycle',
      actor: actor,
      prepare: () async {
        vm = await JudgeScoreWorkspaceLoader.load(
          scoreId: scoreId,
          idea: idea,
          teamLabel: teamLabel,
          templateId: templateId,
          ideathonId: ideathonId,
          departmentCode: departmentCode,
          judge: judge,
        );
      },
      builder: (BuildContext context) => JudgeScoreWorkspaceBody(vm: vm),
    );
  }

  static void push(
    BuildContext context, {
    required String scoreId,
    required IdeaModel idea,
    required String teamLabel,
    required String templateId,
    required String ideathonId,
    required String departmentCode,
    UserModel? judge,
    UserModel? actor,
  }) {
    final String id = scoreId.trim();
    if (id.isEmpty) return;
    final String routeId = 'judgeScore:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(
      context,
      _route(
        scoreId: id,
        idea: idea,
        teamLabel: teamLabel,
        templateId: templateId,
        ideathonId: ideathonId,
        departmentCode: departmentCode,
        judge: judge,
        actor: actor,
      ),
    );
  }
}
