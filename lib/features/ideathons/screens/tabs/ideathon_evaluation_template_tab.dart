import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';
import 'package:hackz/features/evaluations/workspace/evaluation_template_workspace_body.dart';
import 'package:hackz/features/evaluations/workspace/evaluation_template_workspace_loader.dart';

/// Event-scoped Evaluation Template (read-only), reused from the template workspace.
class IdeathonEvaluationTemplateTab extends StatelessWidget {
  const IdeathonEvaluationTemplateTab({
    super.key,
    required this.templateId,
    this.departmentCode,
  });

  final String templateId;
  final String? departmentCode;

  @override
  Widget build(BuildContext context) {
    final String id = templateId.trim();
    if (id.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No evaluation template is linked to this event.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return FutureBuilder<EvaluationTemplateWorkspaceViewModel>(
      future: EvaluationTemplateWorkspaceLoader.load(id, departmentCode: departmentCode),
      builder: (BuildContext context, AsyncSnapshot<EvaluationTemplateWorkspaceViewModel> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: HkzProgressIndicator(size: 32));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              snapshot.hasError
                  ? 'Unable to load evaluation template: ${snapshot.error}'
                  : 'Evaluation template not found',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }
        return EvaluationTemplateWorkspaceBody(vm: snapshot.data!);
      },
    );
  }
}
