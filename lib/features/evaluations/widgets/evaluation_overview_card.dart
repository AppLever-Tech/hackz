import 'package:flutter/material.dart';

import '../../../screens/common/dashboard_components.dart';
import '../../../shared/workspace/user_workspace_avatar.dart';
import '../models/evaluation_details_view_model.dart';
import '../../../widgets/common/context_pill.dart';
import '../../../widgets/common/context_pill_theme.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/shared/workspace/user_workspace_avatar.dart';
import 'package:hackz/widgets/common/context_pill.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

/// Compact evaluation context with workspace launcher pills.
class EvaluationOverviewCard extends StatelessWidget {
  const EvaluationOverviewCard({super.key, required this.vm});

  final EvaluationDetailsViewModel vm;

  static const double _labelWidth = 100;

  @override
  Widget build(BuildContext context) {
    final String ideaId = vm.ideaId.trim();
    final String problemId = vm.idea.problemId.trim();
    final String teamId = vm.teamId.trim();
    final String submitterId = vm.idea.createdBy.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Evaluation Overview',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _pillRow(
            label: 'Idea',
            pillLabel: vm.ideaTitle,
            semantic: ContextPillSemantic.idea,
            onTap: ideaId.isEmpty ? null : () => WorkspaceNavigator.openIdea(context, ideaId),
          ),
          _pillRow(
            label: 'Problem',
            pillLabel: vm.problemTitle,
            semantic: ContextPillSemantic.problem,
            onTap: problemId.isEmpty ? null : () => WorkspaceNavigator.openProblem(context, problemId),
          ),
          _pillRow(
            label: 'Team',
            pillLabel: vm.teamName,
            semantic: ContextPillSemantic.team,
            onTap: teamId.isEmpty ? null : () => WorkspaceNavigator.openTeam(context, teamId),
          ),
          _submittedByRow(context, submitterId),
          _textRow('Department', vm.departmentName, isLast: true),
        ],
      ),
    );
  }

  Widget _submittedByRow(BuildContext context, String submitterId) {
    final String name = vm.submittedByName.trim().isEmpty ? '—' : vm.submittedByName.trim();
    final bool canOpen = submitterId.isNotEmpty && vm.submittedByUser != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: _labelWidth,
            child: Text(
              'Submitted by',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          if (canOpen)
            UserWorkspaceAvatar(
              user: vm.submittedByUser!,
              radius: 12,
              ringPadding: 2,
              onTap: () => WorkspaceNavigator.openUser(context, submitterId),
            )
          else
            _fallbackAvatar(name),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fallbackAvatar(String name) {
    final String initial = name.trim().isEmpty || name == '—' ? '?' : name.trim().substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFEEF2FF),
      child: Text(
        initial,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
      ),
    );
  }

  static Widget _pillRow({
    required String label,
    required String pillLabel,
    required ContextPillSemantic semantic,
    required VoidCallback? onTap,
  }) {
    final String display = pillLabel.trim().isEmpty ? '—' : pillLabel.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Flexible(
            child: ContextPill(
              label: display,
              semantic: semantic,
              onTap: onTap ?? () {},
              enabled: onTap != null,
              compact: true,
              fitContent: true,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _textRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
