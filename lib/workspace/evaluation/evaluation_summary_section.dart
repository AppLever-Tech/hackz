import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import 'evaluation_workspace.dart';
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
                '${vm.totalScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05),
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
        _preview(
          context,
          icon: AppIcons.ideas,
          title: 'Idea',
          headline: vm.ideaTitle,
          detail: vm.scope == EvaluationWorkspaceScope.ideaAggregate
              ? 'Aggregate evaluation report'
              : 'Single judge evaluation',
          onTap: () => EvaluationWorkspace.openIdeaFromEvaluation(context, vm),
        ),
        _preview(
          context,
          icon: AppIcons.judges,
          title: 'Judge',
          headline: vm.primaryJudge?.judgeName ?? '—',
          detail: vm.primaryJudge == null
              ? 'No judge linked'
              : 'Score ${vm.primaryJudge!.overallScore.toStringAsFixed(1)} / 10',
          onTap: vm.primaryJudge == null
              ? null
              : () => EvaluationWorkspace.openUserFromEvaluation(context, vm.primaryJudge!.judgeId),
        ),
        _preview(
          context,
          icon: AppIcons.teams,
          title: 'Team',
          headline: vm.teamName,
          detail: 'Innovation team context',
          onTap: vm.teamId.trim().isEmpty ? null : () => EvaluationWorkspace.openTeamFromEvaluation(context, vm),
        ),
      ],
    );
  }

  static Widget _preview(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String headline,
    required String detail,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: const Color(0xFF57629A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: onTap == null ? const Color(0xFF64748B) : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(AppIcons.openInNew, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
