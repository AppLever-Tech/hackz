import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/faculty_teams_service.dart';
import '../../utils/team_service.dart';
import '../multi_select_dropdown.dart';
import 'student_member_chips.dart';

enum TeamFormDialogAction { none, saved }

class TeamFormDialog extends StatefulWidget {
  const TeamFormDialog({
    super.key,
    required this.currentUser,
    required this.existingTeams,
    required this.departmentStudents,
    this.initialTeam,
  });

  final UserModel currentUser;
  final List<TeamModel> existingTeams;
  final List<UserModel> departmentStudents;
  final TeamModel? initialTeam;

  bool get isEdit => initialTeam != null;

  @override
  State<TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<TeamFormDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedStudentIds = <String>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialTeam?.teamName ?? '';
    _selectedStudentIds.addAll(widget.initialTeam?.studentIds ?? const <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FacultyTeamsService.saveTeam(
        faculty: widget.currentUser,
        teamName: _nameController.text.trim(),
        studentIds: _selectedStudentIds,
        existingTeams: widget.existingTeams,
        departmentStudents: widget.departmentStudents,
        editingTeam: widget.initialTeam,
      );
      if (!mounted) return;
      Navigator.of(context).pop(TeamFormDialogAction.saved);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentorName = '${widget.currentUser.firstName} ${widget.currentUser.lastName}'.trim();
    final editingTeamId = widget.initialTeam?.teamId ?? '';
    final eligibleStudents = widget.departmentStudents.where((student) {
      final assignedTeamId = (student.teamId ?? '').trim();
      return assignedTeamId.isEmpty || assignedTeamId == editingTeamId || _selectedStudentIds.contains(student.userId);
    }).toList(growable: false);
    final selectedNames = _selectedStudentIds
        .map((id) => eligibleStudents.firstWhere(
              (student) => student.userId == id,
              orElse: () => UserModel(
                userId: id,
                phone: '',
                firstName: id,
                lastName: '',
                email: '',
                role: 'STU',
                orgType: widget.currentUser.orgType,
                orgId: widget.currentUser.orgId,
                department: widget.currentUser.department,
                departmentCode: widget.currentUser.departmentCode,
                status: widget.currentUser.status,
                createdAt: DateTime.now(),
              ),
            ))
        .map((student) => '${student.firstName} ${student.lastName}'.trim())
        .toList(growable: false);
    final remaining = (FacultyTeamsService.maxStudentsPerTeam - _selectedStudentIds.length).clamp(0, FacultyTeamsService.maxStudentsPerTeam).toInt();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.teams, color: Color(0xFF6A38FF), size: 24),
              const SizedBox(width: 10),
              Text(widget.isEdit ? 'Edit Team' : 'Create Team', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 14),
          _SectionShell(
            title: 'Team Details',
            icon: AppIcons.teams,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(isDense: true, labelText: 'Team name', border: OutlineInputBorder(), hintText: 'e.g. Team Phoenix'),
            ),
          ),
          const SizedBox(height: 12),
          _SectionShell(
            title: 'Mentor Info',
            icon: AppIcons.faculty,
            child: Row(
              children: <Widget>[
                const Text('Mentor', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                const SizedBox(width: 10),
                Expanded(child: Text(mentorName.isEmpty ? widget.currentUser.userId : mentorName, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionShell(
            title: 'Students',
            icon: AppIcons.student,
            trailing: '$remaining slots left',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MultiSelectDropdown(
                  students: eligibleStudents,
                  selectedIds: _selectedStudentIds,
                  orgId: widget.currentUser.orgId,
                  departmentCode: widget.currentUser.departmentCode,
                  maxSelection: FacultyTeamsService.maxStudentsPerTeam,
                  placeholder: 'Select students',
                  onChanged: (next) => setState(() {
                    _selectedStudentIds
                      ..clear()
                      ..addAll(next);
                  }),
                ),
                const SizedBox(height: 10),
                StudentMemberChips(names: selectedNames),
                const SizedBox(height: 8),
                const Text('Minimum 2 students, maximum 4 students.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Team will be locked after idea submission.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              ),
              OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(TeamFormDialogAction.none), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : (widget.isEdit ? 'Save Changes' : 'Create Team'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: const Color(0xFF6A38FF)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
              if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
