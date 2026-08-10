import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import 'evaluation_template_criteria_section.dart';
import 'evaluation_template_summary_section.dart';
import 'evaluation_template_workspace_loader.dart';

class EvaluationTemplateWorkspaceBody extends StatelessWidget {
  const EvaluationTemplateWorkspaceBody({super.key, required this.vm});

  final EvaluationTemplateWorkspaceViewModel vm;

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
        EvaluationTemplateSummarySection(vm: vm),
        const SizedBox(height: 14),
        EvaluationTemplateCriteriaSection(vm: vm),
      ],
    );
  }
}
