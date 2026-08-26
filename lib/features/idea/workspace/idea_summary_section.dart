import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import 'idea_workspace.dart';
import 'idea_workspace_loader.dart';

class IdeaSummarySection extends StatelessWidget {
  const IdeaSummarySection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final idea = vm.idea;
    final String title = idea.ideaTitle.trim().isEmpty ? 'Innovation proposal' : idea.ideaTitle.trim();
    final String desc = idea.description.trim();

    final String dept = vm.problem.departmentDisplayName.trim().isEmpty
        ? '—'
        : vm.problem.departmentDisplayName.trim();
    final String org = vm.organizationName.trim().isEmpty ? '—' : vm.organizationName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFEAF2FF), Color(0xFFF2EDFF)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(AppIcons.ideas, size: 22, color: Color(0xFF6A38FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.15,
                    ),
                  ),
                  if (desc.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
          ],
        ),
        const SizedBox(height: 12),
        _problemField(context),
        const SizedBox(height: 4),
        _teamField(context),
        const SizedBox(height: 4),
        _labeledField(
          label: 'Department',
          child: _iconValue(AppIcons.departments, dept),
        ),
        const SizedBox(height: 4),
        _labeledField(
          label: 'Organization',
          child: _iconValue(AppIcons.organizations, org),
        ),
      ],
    );
  }

  Widget _problemField(BuildContext context) {
    final String title = vm.problemTitle.trim().isEmpty ? '—' : vm.problemTitle.trim();
    final String problemId =
        vm.problem.problemId.trim().isEmpty ? vm.idea.problemId.trim() : vm.problem.problemId.trim();

    return _labeledField(
      label: 'Problem',
      child: problemId.isEmpty
          ? _plainValue(title)
          : _contextPill(
              label: title,
              semantic: ContextPillSemantic.problem,
              onTap: () => IdeaWorkspace.openProblemFromIdea(context, vm),
            ),
    );
  }

  Widget _teamField(BuildContext context) {
    final String teamName = vm.teamName.trim().isEmpty ? '—' : vm.teamName.trim();
    final String teamId = vm.team.teamId.trim().isEmpty ? vm.idea.teamId.trim() : vm.team.teamId.trim();

    return _labeledField(
      label: 'Team',
      child: teamId.isEmpty
          ? _plainValue(teamName)
          : _contextPill(
              label: teamName,
              semantic: ContextPillSemantic.team,
              onTap: () => IdeaWorkspace.openTeamFromIdea(context, vm),
            ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _contextPill({
    required String label,
    required ContextPillSemantic semantic,
    required VoidCallback onTap,
  }) {
    return ContextPill(
      label: label,
      semantic: semantic,
      onTap: onTap,
      compact: true,
      fitContent: true,
    );
  }

  static Widget _plainValue(String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
    );
  }

  static Widget _iconValue(IconData icon, String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
