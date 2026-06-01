import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../organization/models/department_model.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../workspace/workspace.dart';
import '../workspace/idea_workspace_loader.dart';
import '../widgets/innovation_assets_section.dart';

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        _card(
          title: 'Innovation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Innovation Assets',
          child: InnovationAssetsSection(
            idea: idea,
            attachments: vm.attachments,
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Team Information',
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (teamId.isNotEmpty)
                ContextPillGroup(
                  fieldLabel: 'Team',
                  pillLabel: vm.teamName.trim().isEmpty ? teamId : vm.teamName.trim(),
                  semantic: ContextPillSemantic.team,
                  onOpenWorkspace: () => WorkspaceNavigator.openTeam(context, teamId),
                )
              else
                _plainField('Team', vm.teamName),
              if (vm.mentorId.trim().isNotEmpty)
                ContextPillGroup(
                  fieldLabel: 'Mentor',
                  pillLabel: vm.mentorName.trim().isEmpty ? vm.mentorId.trim() : vm.mentorName.trim(),
                  semantic: ContextPillSemantic.user,
                  onOpenWorkspace: () => WorkspaceNavigator.openUser(context, vm.mentorId.trim()),
                )
              else
                _plainField('Mentor', vm.mentorName),
              EntityCardPills.meta(departmentName, icon: AppIcons.departments),
              EntityCardPills.meta(
                vm.organizationName.trim().isEmpty ? '—' : vm.organizationName.trim(),
                icon: AppIcons.organizations,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Submission Metadata',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _metaRow('Submitted by', vm.submittedByName),
              _metaRow('Submitted on', formatDateTime(idea.createdAt)),
              _metaRow('Status', ideaWorkspaceStatusLabel(idea.status)),
              _contextPillRow(
                label: 'Evaluation',
                child: ContextPillGroup(
                  pillLabel: vm.evaluationProgressLabel,
                  semantic: ContextPillSemantic.evaluation,
                  onOpenWorkspace: () => WorkspaceNavigator.openEvaluation(context, idea.ideaId),
                ),
              ),
              _contextPillRow(
                label: 'Payment',
                child: vm.payment != null
                    ? ContextPillGroup(
                        pillLabel: vm.paymentStatusLabel,
                        semantic: ContextPillSemantic.payment,
                        onOpenWorkspace: () =>
                            WorkspaceNavigator.openPayment(context, vm.payment!.paymentId),
                      )
                    : Text(
                        vm.paymentStatusLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
              ),
            ],
          ),
        ),
        if (vm.attachments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _card(
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

  static Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  static Widget _plainField(String label, String value) {
    return Text(
      '$label: ${value.trim().isEmpty ? '—' : value.trim()}',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
    );
  }

  static Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _contextPillRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
