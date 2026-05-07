import 'package:flutter/material.dart';

import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/team_service.dart';
import '../../widgets/team_dialog.dart';
import '../common/app_dialog_template.dart';
import '../common/dashboard_components.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  Future<_TeamsViewData> _loadTeamsData() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      TeamService.getFacultyTeams(widget.user.userId),
      TeamService.getDepartmentStudents(
        orgId: widget.user.orgId,
        departmentCode: widget.user.departmentCode,
      ),
    ]);
    final teams = results[0] as List<TeamModel>;
    final students = sortUsersByDisplayName(results[1] as List<UserModel>);
    final studentNamesById = <String, String>{
      for (final student in students) student.userId: userDisplayName(student),
    };
    return _TeamsViewData(
      teams: teams,
      studentNamesById: studentNamesById,
    );
  }

  Future<void> _openCreateDialog(List<TeamModel> existing) async {
    if (existing.length >= 3) return;
    final result = await showAppDialog<TeamDialogAction>(
      context: context,
      child: TeamDialog(
        currentUser: widget.user,
        existingTeamCount: existing.length,
      ),
      maxWidth: 740,
    );
    if (result == TeamDialogAction.saved && mounted) {
      setState(() {});
    }
  }

  Future<void> _openEditDialog(TeamModel team, int existingCount) async {
    final result = await showAppDialog<TeamDialogAction>(
      context: context,
      child: TeamDialog(
        currentUser: widget.user,
        initialTeam: team,
        existingTeamCount: existingCount,
      ),
      maxWidth: 740,
    );
    if ((result == TeamDialogAction.saved || result == TeamDialogAction.deleted) && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TeamsViewData>(
      future: _loadTeamsData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load teams: ${snapshot.error}');
        }
        final data = snapshot.data;
        final teams = data?.teams ?? <TeamModel>[];
        final studentNamesById = data?.studentNamesById ?? const <String, String>{};
        final studentsCount = teams.expand((t) => t.studentIds).toSet().length;
        final canCreate = teams.length < 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'My Teams',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canCreate ? () => _openCreateDialog(teams) : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Team'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionContainer(
              child: Row(
                children: <Widget>[
                  _summary('Teams', '${teams.length}/3'),
                  const SizedBox(width: 16),
                  _summary('Students', '$studentsCount'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const SectionContainer(child: Text('No teams created yet.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TeamCard(
                      team: team,
                      mentorName: '${widget.user.firstName} ${widget.user.lastName}'.trim(),
                      studentNamesById: studentNamesById,
                      onEdit: () => _openEditDialog(team, teams.length),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _summary(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.mentorName,
    required this.studentNamesById,
    required this.onEdit,
  });

  final TeamModel team;
  final String mentorName;
  final Map<String, String> studentNamesById;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sortedStudentIds = sortUserIdsByDisplayName(team.studentIds, studentNamesById);
    return SectionContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(team.teamName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton.icon(
                onPressed: team.status.name == 'locked' ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Status: ${team.status.value.toUpperCase()}'),
          const SizedBox(height: 4),
          Text('Mentor: ${mentorName.isEmpty ? '-' : mentorName}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedStudentIds
                .map((id) => Chip(label: Text(studentNamesById[id] ?? id)))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _TeamsViewData {
  const _TeamsViewData({
    required this.teams,
    required this.studentNamesById,
  });

  final List<TeamModel> teams;
  final Map<String, String> studentNamesById;
}
