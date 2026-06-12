import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import 'package:hackz/shared/workspace/entity_reference_tile.dart';
import 'package:hackz/features/idea/workspace/idea_workspace.dart';
import '../../team/workspace/team_workspace.dart';
import '../../user/workspace/user_workspace.dart';
import 'evaluation_workspace_loader.dart';

class EvaluationSummarySection extends StatelessWidget {
  const EvaluationSummarySection({super.key, required this.vm});

  final EvaluationWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF1E1B4B), Color(0xFF4338CA)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(AppIcons.scoring, color: Color(0xFFE0E7FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Evaluation report',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7D2FE),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                vm.evaluationStatusLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE0E7FF)),
              ),
              const SizedBox(height: 6),
              Text(
                '${vm.totalScore.toStringAsFixed(1)} / ${vm.scoringScale}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05),
              ),
              const SizedBox(height: 2),
              Text(
                vm.templateName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1), letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                'Evaluated ${formatDateTime(vm.evaluatedAt)} · ${vm.reviewCompletionLabel}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DashboardMetricChipGrid(
          spacing: 10,
          runSpacing: 10,
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Normalized',
              value: '${vm.normalizedScore.toStringAsFixed(0)}%',
              color: const Color(0xFF6366F1),
              icon: AppIcons.insights,
            ),
            DashboardMetricChipData.single(
              label: 'Ranking',
              value: vm.rankingContribution.toStringAsFixed(1),
              color: const Color(0xFF7C3AED),
              icon: AppIcons.leaderboard,
            ),
            DashboardMetricChipData.single(
              label: 'Reviews',
              value: vm.reviewCompletionLabel,
              color: const Color(0xFF0EA5E9),
              icon: AppIcons.judges,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Related context',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        EntityReferenceTile(
          category: 'Idea',
          headline: vm.ideaTitle,
          detail: vm.scope == EvaluationWorkspaceScope.ideaAggregate
              ? 'Aggregate evaluation report'
              : 'Single judge evaluation',
          semantic: ContextPillSemantic.idea,
          onOpenWorkspace: () => IdeaWorkspace.push(context, vm.idea.ideaId),
        ),
        EntityReferenceTile(
          category: 'Judge',
          headline: vm.primaryJudge?.judgeName ?? '—',
          detail: vm.primaryJudge == null
              ? 'No judge linked'
              : 'Score ${vm.primaryJudge!.overallScore.toStringAsFixed(1)} / ${vm.scoringScale}',
          semantic: ContextPillSemantic.judge,
          onOpenWorkspace: vm.primaryJudge == null
              ? null
              : () => UserWorkspace.push(context, vm.primaryJudge!.judgeId),
        ),
        EntityReferenceTile(
          category: 'Team',
          headline: vm.teamName,
          detail: 'Innovation team context',
          semantic: ContextPillSemantic.team,
          onOpenWorkspace:
              vm.teamId.trim().isEmpty ? null : () => TeamWorkspace.push(context, vm.teamId),
        ),
      ],
    );
  }
}
