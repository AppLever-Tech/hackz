import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../../ideathons/widgets/ideathon_event_workspace_header.dart';
import '../models/evaluation_criterion.dart';
import '../widgets/criterion_score_card.dart';
import 'evaluation_template_workspace.dart';
import 'judge_score_workspace_loader.dart';

class JudgeScoreWorkspaceBody extends StatelessWidget {
  const JudgeScoreWorkspaceBody({super.key, required this.vm});

  final JudgeScoreWorkspaceViewModel vm;

  static const double _labelWidth = 78;

  @override
  Widget build(BuildContext context) {
    final String templateId = vm.template.templateId.trim();
    final String departmentCode = (vm.event?.departmentId ?? vm.idea.problemDepartmentCode).trim();

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        if (vm.event != null) ...<Widget>[
          ideathonEventWorkspaceHeader(
            event: vm.event!,
            organisationName: vm.organisationName,
          ),
          const SizedBox(height: 10),
        ],
        EventLabeledField(
          label: 'Template',
          isLast: true,
          labelWidth: _labelWidth,
          trailing: EntityCardPills.workspace(
            vm.templateLabel,
            ContextPillSemantic.evaluationTemplate,
            () => EvaluationTemplateWorkspace.push(
              context,
              templateId,
              departmentCode: departmentCode,
            ),
            enabled: templateId.isNotEmpty,
            icon: AppIcons.scoring,
          ),
        ),
        const SizedBox(height: 14),
        WorkspaceCollapsibleSection(
          title: 'Criteria',
          icon: AppIcons.checklist,
          count: vm.criteriaCount,
          meta: Text(vm.weightageLabel, style: WorkspaceCollapsibleSection.metaStyle),
          child: vm.criteria.isEmpty
              ? const Text(
                  'No criteria on this evaluation template.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                )
              : Column(
                  children: vm.criteria.map(_criterionCard).toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _criterionCard(JudgeScoreCriterionView row) {
    final EvaluationCriterion c = row.criterion;
    return CriterionScoreCard(
      criterion: c,
      value: row.value,
      readOnly: true,
      onChanged: (_) {},
      weightLabel: row.weightLabel,
      comment: row.comment,
      onCommentChanged: c.commentsEnabled ? (_) {} : null,
      ownershipBadge: c.sourceType == EvaluationCriterionSourceType.department
          ? 'Department specific'
          : null,
    );
  }
}
