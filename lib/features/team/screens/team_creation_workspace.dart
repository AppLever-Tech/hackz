import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../services/teams_workspace_service.dart';
import '../services/team_service.dart';
import '../widgets/team_member_selector.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

enum TeamFormDialogAction { none, saved }

/// Premium team creation / edit workspace.
Future<TeamFormDialogAction?> showTeamCreationWorkspace({
  required BuildContext context,
  required UserModel currentUser,
  required List<TeamModel> existingTeams,
  required List<UserModel> departmentTeamMembers,
  TeamModel? initialTeam,
}) {
  return showDialog<TeamFormDialogAction>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return TeamCreationWorkspace(
        currentUser: currentUser,
        existingTeams: existingTeams,
        departmentTeamMembers: departmentTeamMembers,
        initialTeam: initialTeam,
      );
    },
  );
}

class TeamCreationWorkspace extends StatefulWidget {
  const TeamCreationWorkspace({
    super.key,
    required this.currentUser,
    required this.existingTeams,
    required this.departmentTeamMembers,
    this.initialTeam,
  });

  final UserModel currentUser;
  final List<TeamModel> existingTeams;
  final List<UserModel> departmentTeamMembers;
  final TeamModel? initialTeam;

  bool get isEdit => initialTeam != null;

  @override
  State<TeamCreationWorkspace> createState() => _TeamCreationWorkspaceState();
}

class _TeamCreationWorkspaceState extends State<TeamCreationWorkspace> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedMemberIds = <String>{};
  String _teamLeaderId = '';
  bool _saving = false;

  bool get _isTeamMemberActor => UserRole.fromCode(widget.currentUser.role) == UserRole.teamMember;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialTeam?.teamName ?? '';
    _selectedMemberIds.addAll(widget.initialTeam?.studentIds ?? const <String>[]);
    if (_isTeamMemberActor) {
      _selectedMemberIds.add(widget.currentUser.userId);
      _teamLeaderId = widget.currentUser.userId;
    } else {
      _teamLeaderId = widget.initialTeam?.teamLeaderId.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<UserModel> get _membersForSave {
    if (!_isTeamMemberActor) return widget.departmentTeamMembers;
    if (widget.departmentTeamMembers.any((UserModel u) => u.userId == widget.currentUser.userId)) {
      return widget.departmentTeamMembers;
    }
    return <UserModel>[widget.currentUser, ...widget.departmentTeamMembers];
  }

  List<UserModel> get _eligibleTeamMembers {
    final String editingTeamId = widget.initialTeam?.teamId ?? '';
    return _membersForSave.where((UserModel member) {
      final String assignedTeamId = (member.teamId ?? '').trim();
      return assignedTeamId.isEmpty ||
          assignedTeamId == editingTeamId ||
          _selectedMemberIds.contains(member.userId);
    }).toList(growable: false);
  }

  bool get _canSave {
    if (_saving) return false;
    if (_nameController.text.trim().isEmpty) return false;
    final int count = _selectedMemberIds.length;
    return count >= TeamsWorkspaceService.minMembersPerTeam &&
        count <= TeamsWorkspaceService.maxMembersPerTeam &&
        _teamLeaderId.trim().isNotEmpty &&
        _selectedMemberIds.contains(_teamLeaderId.trim());
  }

  /// Trims only leading/trailing whitespace; internal spaces are preserved.
  String _trimTeamName(String raw) => raw.trim();

  /// Returns a user-facing error when [trimmedName] matches another team
  /// (case-insensitive, ignoring leading/trailing spaces on stored names).
  String? _duplicateTeamNameError(String trimmedName) {
    if (trimmedName.isEmpty) return 'Team name is required.';
    final String normalized = trimmedName.toLowerCase();
    final String editingTeamId = widget.initialTeam?.teamId ?? '';
    for (final TeamModel team in widget.existingTeams) {
      if (team.teamId == editingTeamId) continue;
      if (team.teamName.trim().toLowerCase() == normalized) {
        return 'A team with this name already exists. Choose a different name.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final String trimmedName = _trimTeamName(_nameController.text);
    if (trimmedName != _nameController.text) {
      _nameController.value = _nameController.value.copyWith(
        text: trimmedName,
        selection: TextSelection.collapsed(offset: trimmedName.length),
        composing: TextRange.empty,
      );
    }

    final String? nameError = _duplicateTeamNameError(trimmedName);
    if (nameError != null) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Team name invalid',
        message: nameError,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await TeamsWorkspaceService.saveTeam(
        actor: widget.currentUser,
        teamName: trimmedName,
        studentIds: _selectedMemberIds,
        teamLeaderId: _teamLeaderId,
        existingTeams: widget.existingTeams,
        departmentTeamMembers: _membersForSave,
        editingTeam: widget.initialTeam,
      );
      if (!mounted) return;
      Navigator.of(context).pop(TeamFormDialogAction.saved);
    } on TeamRuleException catch (e) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Cannot save team',
        message: e.message,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.extraWide,
      maxWidth: 900,
      contentPadding: EdgeInsets.zero,
      footer: _buildFooter(context),
      child: _buildBody(context),
    );
  }

  EdgeInsets get _contentPadding {
    if (ResponsiveHelper.isMobile(context)) {
      return const EdgeInsets.fromLTRB(16, 8, 16, 12);
    }
    return const EdgeInsets.fromLTRB(22, 16, 22, 12);
  }

  Widget _buildBody(BuildContext context) {
    final String leaderName = userDisplayName(widget.currentUser);

    return Padding(
      padding: _contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHero(context),
          const SizedBox(height: 12),
          _section(
            title: 'Team identity',
            subtitle: 'Give your innovation team a clear, memorable name',
            child: _buildTeamNameField(context),
          ),
          if (_isTeamMemberActor) ...<Widget>[
            const SizedBox(height: 10),
            _section(
              title: 'Team Leader',
              subtitle: 'You lead this team',
              compact: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ContextPill(
                  label: leaderName.isEmpty ? 'Team Leader' : leaderName,
                  semantic: ContextPillSemantic.user,
                  icon: AppIcons.teamMember,
                  onTap: () => WorkspaceNavigator.openUser(
                    context,
                    widget.currentUser.userId,
                    actor: widget.currentUser,
                  ),
                  compact: true,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _section(
            title: 'Team Members',
            subtitle:
                'Select ${TeamsWorkspaceService.minMembersPerTeam}–${TeamsWorkspaceService.maxMembersPerTeam} team members for collaborative submission',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TeamMemberSelector(
                  members: _eligibleTeamMembers,
                  selectedIds: _selectedMemberIds,
                  maxSelection: TeamsWorkspaceService.maxMembersPerTeam,
                  enabled: !_saving,
                  onChanged: (Set<String> next) => setState(() {
                    _selectedMemberIds
                      ..clear()
                      ..addAll(next);
                    if (_isTeamMemberActor) {
                      _selectedMemberIds.add(widget.currentUser.userId);
                      _teamLeaderId = widget.currentUser.userId;
                    } else if (_teamLeaderId.isNotEmpty && !_selectedMemberIds.contains(_teamLeaderId)) {
                      _teamLeaderId = '';
                    }
                  }),
                ),
                const SizedBox(height: 8),
                _buildRulesHint(context),
                if (!_isTeamMemberActor) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildTeamLeaderField(),
                ],
              ],
            ),
          ),
          if (!widget.isEdit) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Teams lock after the first idea submission.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF8F5FF), Color(0xFFF1F5FF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF7C3AED), Color(0xFF4A67FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(AppIcons.teams, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.isEdit ? 'Edit Innovation Team' : 'Create Innovation Team',
                      style: TextStyle(
                        fontSize: mobile ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Build a collaborative innovation team for idea submission.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _heroChip('${TeamsWorkspaceService.minMembersPerTeam}–${TeamsWorkspaceService.maxMembersPerTeam} team members'),
              _heroChip('Team Leader'),
              _heroChip('Submission ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildTeamNameField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _nameController,
        enabled: !_saving,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          height: 1.2,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Enter team name',
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLeaderField() {
    final List<UserModel> selectedMembers = _membersForSave
        .where((UserModel u) => _selectedMemberIds.contains(u.userId))
        .toList(growable: false);
    final String? value = selectedMembers.any((UserModel u) => u.userId == _teamLeaderId) ? _teamLeaderId : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Team Leader',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        HackzSelectField<String>(
          value: value,
          hint: selectedMembers.isEmpty ? 'Select members first' : 'Select team leader',
          enabled: !_saving && selectedMembers.isNotEmpty,
          prefixIcon: AppIcons.teamMember,
          options: selectedMembers.map((UserModel u) => u.userId).toList(growable: false),
          labelBuilder: (String id) {
            for (final UserModel u in selectedMembers) {
              if (u.userId == id) return userDisplayName(u);
            }
            return id;
          },
          onChanged: (String id) => setState(() => _teamLeaderId = id),
        ),
      ],
    );
  }

  Widget _buildRulesHint(BuildContext context) {
    final int count = _selectedMemberIds.length;
    final bool belowMin = count < TeamsWorkspaceService.minMembersPerTeam;
    final bool atMax = count >= TeamsWorkspaceService.maxMembersPerTeam;

    return Row(
      children: <Widget>[
        Icon(
          belowMin ? AppIcons.workflowPendingReview : (atMax ? AppIcons.workflowApproved : AppIcons.statusActive),
          size: 14,
          color: belowMin ? const Color(0xFFB45309) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            belowMin
                ? 'Add at least ${TeamsWorkspaceService.minMembersPerTeam} team members to continue.'
                : 'Minimum ${TeamsWorkspaceService.minMembersPerTeam} team members · maximum ${TeamsWorkspaceService.maxMembersPerTeam} team members.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: belowMin ? const Color(0xFFB45309) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final int count = _selectedMemberIds.length;
    final int remaining =
        (TeamsWorkspaceService.maxMembersPerTeam - count).clamp(0, TeamsWorkspaceService.maxMembersPerTeam).toInt();
    final bool ready = _canSave;

    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _footerMeta(AppIcons.teamMember, '$count team member${count == 1 ? '' : 's'} selected'),
              _footerMeta(AppIcons.teams, '$remaining slot${remaining == 1 ? '' : 's'} left'),
              _footerMeta(
                ready ? AppIcons.workflowApproved : AppIcons.workflowPendingReview,
                ready ? 'Ready to create' : 'Complete team details',
                color: ready ? const Color(0xFF059669) : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(TeamFormDialogAction.none),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(AppIcons.teams, size: 18),
                  label: Text(widget.isEdit ? 'Save Team' : 'Create Team'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: const Color(0xFF6A38FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerMeta(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    String? subtitle,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          SizedBox(height: compact ? 6 : 8),
          child,
        ],
      ),
    );
  }
}
