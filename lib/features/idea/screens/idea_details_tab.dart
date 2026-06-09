import 'package:flutter/material.dart';

import '../../organization/models/department_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../workspace/idea_workspace_loader.dart';
import '../widgets/idea_evaluation_results_section.dart';
import '../widgets/innovation_assets_section.dart';
import 'package:hackz/core/workspace/workspace_attachments_panel.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

/// Idea Details tab for [IdeaDetailsPane].
class IdeaDetailsTab extends StatelessWidget {
  const IdeaDetailsTab({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.idea;
    final String title = idea.ideaTitle.trim().isEmpty ? 'Untitled innovation' : idea.ideaTitle.trim();
    final String description = idea.description.trim();
    final String teamId = vm.team.teamId.trim().isNotEmpty ? vm.team.teamId.trim() : idea.teamId.trim();
    final String departmentName = DepartmentModel.byCode(idea.teamDepartmentCode)?.name ??
        (idea.teamDepartmentCode.trim().isEmpty ? '—' : idea.teamDepartmentCode.trim());

    final bool isMobile = ResponsiveHelper.isMobile(context);
    final double labelWidth = isMobile ? 92 : 112;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      children: <Widget>[
        _card(
          context: context,
          title: 'Innovation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
          title: 'Evaluation Results',
          child: IdeaEvaluationResultsSection(idea: idea),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
          title: 'Innovation Assets',
          child: InnovationAssetsSection(
            idea: idea,
            attachments: vm.attachments,
          ),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
          title: 'Team Information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (teamId.isNotEmpty)
                _labeledContextPillRow(
                  context: context,
                  labelWidth: labelWidth,
                  label: 'Team',
                  pillLabel: vm.teamName.trim().isEmpty ? teamId : vm.teamName.trim(),
                  semantic: ContextPillSemantic.team,
                  onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                )
              else
                _metaRow(context, labelWidth: labelWidth, label: 'Team', value: vm.teamName),
              if (vm.mentorId.trim().isNotEmpty)
                _labeledContextPillRow(
                  context: context,
                  labelWidth: labelWidth,
                  label: 'Mentor',
                  pillLabel: vm.mentorName.trim().isEmpty ? vm.mentorId.trim() : vm.mentorName.trim(),
                  semantic: ContextPillSemantic.user,
                  onTap: () => WorkspaceNavigator.openUser(context, vm.mentorId.trim()),
                )
              else
                _metaRow(context, labelWidth: labelWidth, label: 'Mentor', value: vm.mentorName),
              _metaRow(
                context,
                labelWidth: labelWidth,
                label: 'Department',
                value: departmentName,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
          title: 'Submission Metadata',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _metaRow(context, labelWidth: labelWidth, label: 'Submitted by', value: vm.submittedByName),
              _metaRow(
                context,
                labelWidth: labelWidth,
                label: 'Submitted on',
                value: formatDateTime(idea.createdAt),
              ),
              _metaRow(
                context,
                labelWidth: labelWidth,
                label: 'Status',
                value: ideaWorkspaceStatusLabel(idea.status),
              ),
              _labeledContextPillRow(
                context: context,
                labelWidth: labelWidth,
                label: 'Evaluation',
                pillLabel: vm.evaluationProgressLabel,
                semantic: ContextPillSemantic.evaluation,
                onTap: () => WorkspaceNavigator.openEvaluation(context, idea.ideaId),
              ),
              if (vm.payment != null)
                _labeledContextPillRow(
                  context: context,
                  labelWidth: labelWidth,
                  label: 'Payment',
                  pillLabel: vm.paymentStatusLabel,
                  semantic: ContextPillSemantic.payment,
                  onTap: () => WorkspaceNavigator.openPayment(context, vm.payment!.paymentId),
                  isLast: true,
                )
              else
                _metaRow(
                  context,
                  labelWidth: labelWidth,
                  label: 'Payment',
                  value: vm.paymentStatusLabel,
                  isLast: true,
                ),
            ],
          ),
        ),
        if (vm.attachments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _card(
            context: context,
            title: 'All Attachments',
            child: WorkspaceAttachmentsPanel(
              attachments: vm.attachments,
              emptyMessage: 'No attachments.',
            ),
          ),
        ],
      ],
    );
  }

  static Widget _card({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final bool isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 8 : 10),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  static Widget _labeledContextPillRow({
    required BuildContext context,
    required double labelWidth,
    required String label,
    required String pillLabel,
    required ContextPillSemantic semantic,
    required VoidCallback onTap,
    bool enabled = true,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          ContextPill(
            label: pillLabel,
            semantic: semantic,
            onTap: onTap,
            enabled: enabled,
            compact: true,
            fitContent: true,
          ),
        ],
      ),
    );
  }

  static Widget _metaRow(
    BuildContext _, {
    required double labelWidth,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
