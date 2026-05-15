import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/idea_model.dart';
import '../../models/problem_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';

class TeamContributionSection extends StatelessWidget {
  const TeamContributionSection({
    super.key,
    required this.teamName,
    required this.mentorName,
    required this.students,
    required this.ideaTitle,
    required this.problemTitle,
    this.problemDescription,
  });

  final String teamName;
  final String mentorName;
  final List<UserModel> students;
  final String ideaTitle;
  final String problemTitle;
  final String? problemDescription;

  factory TeamContributionSection.fromModels({
    required TeamModel? team,
    required String mentorName,
    required List<UserModel> students,
    required IdeaModel? idea,
    required ProblemModel? problem,
  }) {
    return TeamContributionSection(
      teamName: team?.teamName.trim().isNotEmpty == true ? team!.teamName.trim() : (team?.teamId ?? '-'),
      mentorName: mentorName,
      students: students,
      ideaTitle: idea?.ideaTitle.trim().isNotEmpty == true ? idea!.ideaTitle.trim() : 'Untitled Idea',
      problemTitle: problem?.title.trim().isNotEmpty == true
          ? problem!.title.trim()
          : (idea?.problemTitle.trim().isNotEmpty == true ? idea!.problemTitle.trim() : 'Problem'),
      problemDescription: problem?.description.trim().isNotEmpty == true ? problem!.description.trim() : idea?.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _sectionTitle(AppIcons.teams, 'Team contribution'),
        const SizedBox(height: 8),
        _line(AppIcons.teams, 'Team', teamName),
        const SizedBox(height: 6),
        _line(AppIcons.faculty, 'Mentor', mentorName),
        const SizedBox(height: 8),
        const Text('Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        if (students.isEmpty)
          const Text('No students linked', style: TextStyle(color: Color(0xFF94A3B8)))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: students.map(_studentPill).toList(growable: false),
          ),
        const SizedBox(height: 10),
        _line(AppIcons.ideas, 'Idea', ideaTitle),
        const SizedBox(height: 6),
        _line(AppIcons.problems, 'Problem', problemTitle),
        if (problemDescription != null && problemDescription!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            problemDescription!.trim(),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
          ),
        ],
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

  static Widget _studentPill(UserModel student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(AppIcons.student, size: 14, color: Color(0xFF6A38FF)),
          const SizedBox(width: 5),
          Text(
            userDisplayName(student),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              children: <TextSpan>[
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
