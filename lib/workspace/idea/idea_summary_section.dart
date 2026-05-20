import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/idea_model.dart';
import '../../utils/common_helpers.dart';
import 'idea_workspace.dart';
import 'idea_workspace_loader.dart';

class IdeaSummarySection extends StatelessWidget {
  const IdeaSummarySection({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.idea;
    final String title = idea.ideaTitle.trim().isEmpty ? 'Innovation proposal' : idea.ideaTitle.trim();
    final String desc = idea.description.trim();
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
        _problemTitleChip(context),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxChipWidth = constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _chip(AppIcons.teams, 'Team', vm.teamName, maxWidth: maxChipWidth),
                _chip(AppIcons.faculty, 'Mentor', vm.mentorName, maxWidth: maxChipWidth),
                _chip(AppIcons.organizations, 'Organization', vm.organizationName, maxWidth: maxChipWidth),
                _statusChip(idea.status),
                _chip(AppIcons.clock, 'Submitted', formatDateTime(idea.createdAt), maxWidth: maxChipWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _problemTitleChip(BuildContext context) {
    final String title = vm.problemTitle.trim().isEmpty ? '—' : vm.problemTitle.trim();
    final String problemId =
        vm.problem.problemId.trim().isEmpty ? vm.idea.problemId.trim() : vm.problem.problemId.trim();
    final bool canOpen = problemId.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canOpen ? () => IdeaWorkspace.openProblemFromIdea(context, vm) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: <Widget>[
              const Icon(AppIcons.problems, size: 15, color: Color(0xFF57629A)),
              const SizedBox(width: 6),
              const Text(
                'Problem: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: canOpen ? const Color(0xFF334155) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chip(IconData icon, String label, String value, {required double maxWidth}) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 15, color: const Color(0xFF57629A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label: $text',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statusChip(IdeaStatus status) {
    final Color color = StatusStyles.colorForIdeaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(StatusStyles.iconForIdeaStatus(status), size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            ideaWorkspaceStatusLabel(status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
