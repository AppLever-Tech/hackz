import 'package:flutter/material.dart';

import '../../models/score_model.dart';
import '../../utils/common_helpers.dart';
import '../core/workspace_host.dart';
import '../core/workspace_route.dart';
import '../payment/payment_workspace.dart';
import '../problem/problem_workspace.dart';
import '../team/team_workspace.dart';
import 'idea_workspace_body.dart';
import 'idea_workspace_loader.dart';

/// Read-only innovation proposal workspace for a Hackz idea.
abstract final class IdeaWorkspace {
  static WorkspaceRoute _route(String id) {
    late IdeaWorkspaceViewModel vm;
    return WorkspaceRoute(
      id: 'idea:$id',
      title: 'Idea Details',
      subtitle: WorkspaceRoute.loadingSubtitle,
      prepare: () async {
        vm = await IdeaWorkspaceLoader.load(id);
      },
      builder: (BuildContext context) => IdeaWorkspaceBody(vm: vm),
    );
  }

  /// Opens the idea workspace (replaces the current workspace stack).
  static void open(BuildContext context, String ideaId) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.open(context, _route(id));
  }

  /// Pushes the idea workspace on top of the current route.
  static void push(BuildContext context, String ideaId) {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final String routeId = 'idea:$id';
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == routeId) return;
    HkzWorkspace.push(context, _route(id));
  }

  static void openProblemFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String id = vm.problem.problemId.trim().isEmpty ? vm.idea.problemId.trim() : vm.problem.problemId.trim();
    if (id.isEmpty) return;
    ProblemWorkspace.push(context, id);
  }

  static void openTeamFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String id = vm.team.teamId.trim().isEmpty ? vm.idea.teamId.trim() : vm.team.teamId.trim();
    if (id.isEmpty) return;
    TeamWorkspace.push(context, id);
  }

  static void openPaymentFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    final String paymentId = vm.payment?.paymentId.trim() ?? '';
    if (paymentId.isEmpty) return;
    PaymentWorkspace.push(context, paymentId);
  }

  static void openEvaluationFromIdea(BuildContext context, IdeaWorkspaceViewModel vm) {
    if (vm.scores.isEmpty) return;
    final current = HkzWorkspace.controllerOf(context).current;
    if (current != null && current.id == 'evaluation:${vm.idea.ideaId}') return;
    HkzWorkspace.push(
      context,
      WorkspaceRoute(
        id: 'evaluation:${vm.idea.ideaId}',
        title: 'Evaluation Details',
        builder: (BuildContext context) => IdeaEvaluationPreviewRoute(vm: vm),
      ),
    );
  }
}

/// Read-only evaluation summary pushed from the idea workspace.
class IdeaEvaluationPreviewRoute extends StatelessWidget {
  const IdeaEvaluationPreviewRoute({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Text(
          vm.averageScore == null ? 'No composite score yet' : 'Average ${vm.averageScore!.toStringAsFixed(1)} / 10',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          vm.evaluationProgressLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        ...vm.scores.map((ScoreModel score) {
          final String judge = vm.judgeNamesById[score.judgeId.trim()] ?? score.judgeId;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${score.score.toStringAsFixed(1)} / 10 · $judge',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
                if (score.feedback.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    score.feedback.trim(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatDateTime(score.createdAt),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
