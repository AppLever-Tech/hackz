import 'package:flutter/material.dart';

import '../../../core/workspace/workspace_theme.dart';
import 'evaluation_template_criteria_section.dart';
import 'evaluation_template_summary_section.dart';
import 'evaluation_template_workspace_loader.dart';

class EvaluationTemplateWorkspaceBody extends StatelessWidget {
  const EvaluationTemplateWorkspaceBody({super.key, required this.vm});

  final EvaluationTemplateWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        EvaluationTemplateSummarySection(vm: vm),
        const SizedBox(height: 14),
        EvaluationTemplateCriteriaSection(vm: vm),
      ],
    );
  }
}
