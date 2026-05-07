import 'package:flutter/material.dart';

import '../models/enums/team_status.dart';
import '../models/enums/user_status.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../utils/team_service.dart';
import '../screens/common/app_dialog_template.dart';
import 'multi_select_dropdown.dart';

enum TeamDialogAction { none, saved, deleted }

class TeamDialog extends StatefulWidget {
  const TeamDialog({
    super.key,
    required this.currentUser,
    required this.existingTeamCount,
    this.initialTeam,
  });

  final UserModel currentUser;
  final TeamModel? initialTeam;
  final int existingTeamCount;

  bool get isEdit => initialTeam != null;

  @override
  State<TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<TeamDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedStudentIds = <String>{};
  bool _isSaving = false;

  List<UserModel> _students = <UserModel>[];
  List<TeamModel> _facultyTeams = <TeamModel>[];

  bool get _isEdit => widget.isEdit;
  TeamModel? get _editingTeam => widget.initialTeam;
  bool get _isLocked => _editingTeam?.status == TeamStatus.locked;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialTeam?.teamName ?? '';
    _selectedStudentIds.addAll(widget.initialTeam?.studentIds ?? const <String>[]);
    _loadLookups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      TeamService.getDepartmentStudents(
        orgId: widget.currentUser.orgId,
        departmentCode: widget.currentUser.departmentCode,
      ),
      TeamService.getFacultyTeams(widget.currentUser.userId),
    ]);

    if (!mounted) return;
    final students = results[0] as List<UserModel>;
    final teams = results[1] as List<TeamModel>;
    final editableTeamId = _editingTeam?.teamId ?? '';
    final eligibleStudents = students.where((s) {
      final assignedTeamId = (s.teamId ?? '').trim();
      return assignedTeamId.isEmpty ||
          assignedTeamId == editableTeamId ||
          _selectedStudentIds.contains(s.userId);
    }).toList(growable: false);
    setState(() {
      _students = eligibleStudents;
      _facultyTeams = teams;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (_isLocked) return;

    setState(() => _isSaving = true);
    try {
      await TeamService.validateTeamUpsert(
        faculty: widget.currentUser,
        teamName: name,
        selectedStudentIds: _selectedStudentIds,
        existingTeams: _facultyTeams,
        departmentStudents: _students,
        editingTeam: _editingTeam,
      );
      if (_isEdit) {
        await TeamService.updateTeam(
          team: _editingTeam!,
          teamName: name,
          studentIds: _selectedStudentIds,
        );
      } else {
        await TeamService.createTeam(
          faculty: widget.currentUser,
          teamName: name,
          studentIds: _selectedStudentIds,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(TeamDialogAction.saved);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Team?'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await TeamService.deleteTeam(widget.initialTeam!);
    if (!mounted) return;
    Navigator.of(context).pop(TeamDialogAction.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final mentorName = '${widget.currentUser.firstName} ${widget.currentUser.lastName}'.trim();

    return AppDialogTemplate(
      maxWidth: 760,
      showBorder: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.groups_2_outlined, color: Color(0xFF2F6BFF), size: 22),
              const SizedBox(width: 8),
              Text(
                _isEdit ? 'Edit team' : 'Create team',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLocked)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Team is locked after idea submission. No student changes allowed.',
                style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Team will be locked after idea submission.',
                style: TextStyle(color: Color(0xFF5A5F87)),
              ),
            ),
          const _SectionHeader(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Team details',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              children: <Widget>[
                _InlineField(
                  label: 'Team name',
                  child: TextField(
                    controller: _nameController,
                    enabled: !_isLocked,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Team Phoenix',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionHeader(
            icon: Icons.school_outlined,
            title: 'Mentor',
            trailingText: mentorName.isEmpty ? widget.currentUser.userId : mentorName,
          ),
          const SizedBox(height: 10),
          const _SectionHeader(
            icon: Icons.groups_outlined,
            title: 'Students',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MultiSelectDropdown(
                  students: _students,
                  selectedIds: _selectedStudentIds,
                  orgId: widget.currentUser.orgId,
                  departmentCode: widget.currentUser.departmentCode,
                  maxSelection: 4,
                  placeholder: 'Select student',
                  enabled: !_isLocked,
                  onChanged: (next) {
                    setState(() {
                      _selectedStudentIds
                        ..clear()
                        ..addAll(next);
                    });
                  },
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _selectedStudentIds
                          .map((id) => _students.firstWhere(
                                (s) => s.userId == id,
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
                                  status: UserStatus.active,
                                  createdAt: DateTime.now(),
                                ),
                              ))
                          .map(
                            (student) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text('${student.firstName} ${student.lastName}'.trim()),
                                onDeleted: _isLocked ? null : () => setState(() => _selectedStudentIds.remove(student.userId)),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              if (_isEdit)
                OutlinedButton.icon(
                  onPressed: _isSaving || _isLocked ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Team'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _isSaving || _isLocked ? null : _save,
                child: Text(_isSaving ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Create Team')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(TeamDialogAction.none),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD8E4FF)),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2F6BFF)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (trailingText != null) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trailingText!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
