import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_theme.dart';
import 'evaluation_feedback_section.dart';
import 'evaluation_judge_section.dart';
import 'evaluation_scores_section.dart';
import 'evaluation_summary_section.dart';
import 'evaluation_workspace_loader.dart';

class EvaluationWorkspaceBody extends StatelessWidget {
  const EvaluationWorkspaceBody({super.key, required this.vm});

  final EvaluationWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        EvaluationSummarySection(vm: vm),
        const SizedBox(height: 14),
        EvaluationScoresSection(vm: vm),
        const SizedBox(height: 14),
        EvaluationJudgeSection(vm: vm),
        const SizedBox(height: 14),
        EvaluationFeedbackSection(vm: vm),
      ],
    );
  }
}
