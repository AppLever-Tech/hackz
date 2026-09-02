import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_columns.dart';
import '../../../core/workspace/workspace_host.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../ideathons/widgets/ideathon_event_workspace_header.dart';
import '../../user/models/user_model.dart';
import '../models/evaluation_details_view_model.dart';
import '../widgets/evaluation_judge_breakdown_panel.dart';
import '../widgets/evaluation_overview_card.dart';
import '../widgets/evaluation_score_distribution.dart';
import '../widgets/evaluation_summary_cards.dart';
import 'judge_score_workspace.dart';

/// Layout variant for [EvaluationWorkspaceBody].
enum EvaluationDetailsLayout {
  /// Full evaluation results overlay (metrics, full judge rows).
  pane,

  /// Side workspace opened from a context pill (compact judge rows, no metric cards).
  workspace,
}

/// Evaluation-centric scrollable body (shared by pane + side workspace).
class EvaluationWorkspaceBody extends StatelessWidget {
  const EvaluationWorkspaceBody({
    super.key,
    required this.vm,
    this.layout = EvaluationDetailsLayout.pane,
    this.actor,
  });

  final EvaluationDetailsViewModel vm;
  final EvaluationDetailsLayout layout;
  final UserModel? actor;

  @override
  Widget build(BuildContext context) {
    final bool workspace = layout == EvaluationDetailsLayout.workspace;
    final EdgeInsets pad = WorkspaceTheme.bodyPadding(context);

    final Widget overviewDistributionRow = ResponsivePair(
      spacing: 12,
      firstFlex: 1,
      secondFlex: 1,
      first: EvaluationOverviewCard(vm: vm),
      second: EvaluationScoreDistribution(
        judgeDetails: vm.judgeDetails,
        scoringScale: vm.scoringScale,
      ),
    );

    return ListView(
      padding: pad,
      children: <Widget>[
        if (vm.event != null) ...<Widget>[
          ideathonEventWorkspaceHeader(
            event: vm.event!,
            organisationName: vm.organisationName,
          ),
          const SizedBox(height: 14),
        ],
        if (!workspace) ...<Widget>[
          EvaluationSummaryCards(
            idea: vm.idea,
            aggregateOverride: vm.aggregateOverride,
          ),
          const SizedBox(height: 14),
        ],
        overviewDistributionRow,
        const SizedBox(height: 14),
        EvaluationJudgeBreakdownPanel(
          judgeDetails: vm.judgeDetails,
          departmentCode: vm.idea.problemDepartmentCode,
          compactRows: workspace,
          onScoreTap: (EvaluationJudgeDetail detail) {
            JudgeScoreWorkspace.push(
              context,
              scoreId: detail.scoreId,
              idea: vm.idea,
              teamLabel: vm.teamName,
              templateId: detail.templateId,
              ideathonId: vm.ideathonId,
              departmentCode: vm.idea.problemDepartmentCode,
              judge: detail.judgeUser,
              actor: actor ?? HkzWorkspace.controllerOf(context).actor,
            );
          },
        ),
      ],
    );
  }
}
