import 'package:flutter/material.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/features/evaluations/models/evaluation_criterion.dart';
import 'package:hackz/features/evaluations/models/evaluation_template.dart';
import 'package:hackz/features/evaluations/services/evaluation_templates_service.dart';
import 'package:hackz/features/events/widgets/event_evaluation_template_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
import 'package:hackz/features/user/models/enums/user_role.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/features/user/services/role_visibility_helpers.dart';

/// Event-scoped evaluation template: review inherited criteria, add extensions,
/// lock after the event starts.
class IdeathonEvaluationTemplateTab extends StatelessWidget {
  const IdeathonEvaluationTemplateTab({
    super.key,
    required this.vm,
    required this.actor,
    this.onSaved,
  });

  final IdeathonDetailsViewModel vm;
  final UserModel actor;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) {
    final String templateId = vm.ideathon.evaluationTemplateId.trim();
    if (templateId.isEmpty) {
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

    final EvaluationTemplate template = EvaluationTemplatesService.resolveForEvent(
      templateId: templateId,
      departmentCode: vm.ideathon.departmentId,
      eventCriteria: vm.ideathon.evaluationCriteria,
    );
    final bool canManage = RoleVisibilityHelpers.canCreateIdeathon(UserRole.fromCode(actor.role));
    final bool locked = IdeathonService.isEvaluationTemplateLocked(
      vm.ideathon,
      evaluationStarted: vm.workspace.evaluationStarted,
    );

    return EventEvaluationTemplateSection(
      template: template,
      departmentCode: vm.ideathon.departmentId,
      locked: locked,
      canManage: canManage,
      lockedMessage: IdeathonService.evaluationTemplateLockMessage(
        vm.ideathon,
        evaluationStarted: vm.workspace.evaluationStarted,
      ),
      onSave: (List<EvaluationCriterion> criteria) async {
        try {
          await IdeathonService.updateEvaluationCriteria(
            actor: actor,
            ideathonId: vm.ideathon.ideathonId,
            criteria: criteria,
          );
          if (!context.mounted) return;
          FeedbackService.showSuccess(
            context,
            title: 'Template saved',
            message: 'This event’s evaluation template is ready. Total weightage is 100%.',
          );
          onSaved?.call();
        } catch (e) {
          if (!context.mounted) return;
          FeedbackService.showError(
            context,
            title: 'Could not save template',
            message: '$e',
          );
        }
      },
    );
  }
}
