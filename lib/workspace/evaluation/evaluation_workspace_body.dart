import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
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
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    return ListView(
      padding: pad,
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
