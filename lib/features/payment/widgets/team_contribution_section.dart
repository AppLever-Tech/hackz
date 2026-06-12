import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/problems/models/problem_model.dart';
import 'package:hackz/features/team/models/team_model.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/workspace/user_workspace_avatar.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

import 'payment_form_row.dart';

class TeamContributionSection extends StatelessWidget {
  const TeamContributionSection({
    super.key,
    this.teamId,
    required this.teamName,
    this.mentor,
    required this.students,
    required this.ideaTitle,
    this.ideaId,
    required this.problemTitle,
    this.problemId,
  });

  final String? teamId;
  final String teamName;
  final UserModel? mentor;
  final List<UserModel> students;
  final String ideaTitle;
  final String? ideaId;
  final String problemTitle;
  final String? problemId;

  factory TeamContributionSection.fromModels({
    required TeamModel? team,
    UserModel? mentor,
    required List<UserModel> students,
    required IdeaModel? idea,
    required ProblemModel? problem,
  }) {
    return TeamContributionSection(
      teamId: team?.teamId,
      teamName: team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : (team?.teamId ?? '-'),
      mentor: mentor,
      students: students,
      ideaTitle: idea?.ideaTitle.trim().isNotEmpty == true ? idea!.ideaTitle.trim() : 'Untitled Idea',
      ideaId: idea?.ideaId,
      problemTitle: problem?.title.trim().isNotEmpty == true
          ? problem!.title.trim()
          : (idea?.problemTitle.trim().isNotEmpty == true ? idea!.problemTitle.trim() : 'Problem'),
      problemId: problem?.problemId ?? idea?.problemId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _sectionTitle(AppIcons.teams, 'Team contribution'),
        const SizedBox(height: 8),
        PaymentFormRow(
          icon: AppIcons.teams,
          label: 'Team',
          value: _teamValue(context),
        ),
        PaymentFormRow(
          icon: AppIcons.faculty,
          label: 'Mentor',
          value: _mentorValue(context),
        ),
        PaymentFormRow(
          icon: AppIcons.student,
          label: 'Students',
          value: _studentsValue(context),
        ),
        PaymentFormRow(
          icon: AppIcons.ideas,
          label: 'Idea',
          value: _ideaValue(context),
        ),
        PaymentFormRow(
          icon: AppIcons.problems,
          label: 'Problem',
          value: _problemValue(context),
          bottomPadding: 0,
        ),
      ],
    );
  }

  static Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF6A38FF), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _teamValue(BuildContext context) {
    final String id = teamId?.trim() ?? '';
    if (id.isEmpty) {
      return PaymentFormRow.plainValue(teamName);
    }
    return _compactPill(
      label: teamName,
      semantic: ContextPillSemantic.team,
      onTap: () => WorkspaceNavigator.openTeam(context, id),
    );
  }

  Widget _mentorValue(BuildContext context) {
    final UserModel? mentorUser = mentor;
    final String name = mentorUser == null
        ? '-'
        : userDisplayName(mentorUser);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (mentorUser != null)
          UserWorkspaceAvatar(
            user: mentorUser,
            radius: 12,
            ringPadding: 2,
            onTap: () => WorkspaceNavigator.openUser(context, mentorUser.userId),
          )
        else
          PaymentFormRow.fallbackAvatar(name, radius: 12),
        const SizedBox(width: 8),
        Expanded(child: PaymentFormRow.plainValue(name)),
      ],
    );
  }

  Widget _studentsValue(BuildContext context) {
    if (students.isEmpty) {
      return PaymentFormRow.plainValue('No students linked');
    }

    final List<Widget> rows = <Widget>[];
    for (var i = 0; i < students.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < students.length ? 8 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _studentRow(context, students[i])),
              if (i + 1 < students.length) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(child: _studentRow(context, students[i + 1])),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _studentRow(BuildContext context, UserModel student) {
    final String name = userDisplayName(student);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        UserWorkspaceAvatar(
          user: student,
          radius: 12,
          ringPadding: 2,
          onTap: () => WorkspaceNavigator.openUser(context, student.userId),
        ),
        const SizedBox(width: 8),
        Expanded(child: PaymentFormRow.plainValue(name)),
      ],
    );
  }

  Widget _ideaValue(BuildContext context) {
    final String id = ideaId?.trim() ?? '';
    if (id.isEmpty) {
      return PaymentFormRow.plainValue(ideaTitle);
    }
    return _compactPill(
      label: ideaTitle,
      semantic: ContextPillSemantic.idea,
      onTap: () => WorkspaceNavigator.openIdea(context, id),
    );
  }

  Widget _problemValue(BuildContext context) {
    final String id = problemId?.trim() ?? '';
    if (id.isEmpty) {
      return PaymentFormRow.plainValue(problemTitle);
    }
    return _compactPill(
      label: problemTitle,
      semantic: ContextPillSemantic.problem,
      onTap: () => WorkspaceNavigator.openProblem(context, id),
    );
  }

  static Widget _compactPill({
    required String label,
    required ContextPillSemantic semantic,
    required VoidCallback onTap,
  }) {
    final String text = label.trim().isEmpty ? '—' : label.trim();
    return ContextPill(
      label: text,
      semantic: semantic,
      onTap: onTap,
      compact: true,
      fitContent: true,
    );
  }
}
