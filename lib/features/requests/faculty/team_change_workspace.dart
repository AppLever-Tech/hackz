import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../team/models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../utils/common_helpers.dart';
import '../../team/services/faculty_teams_service.dart';
import '../../team/widgets/team_student_selector.dart';
import '../models/team_change_request.dart';
import '../models/workflow_request.dart';
import '../models/workflow_request_type.dart';
import '../models/workflow_status.dart';
import '../services/team_change_request_service.dart';
import '../services/workflow_request_service.dart';
import '../widgets/request_workspace_section.dart';
import '../widgets/team_change_history_timeline.dart';
import '../widgets/team_member_diff_view.dart';
import '../widgets/workflow_evaluation_warning.dart';
import '../widgets/workflow_status_pill.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

/// Full-screen "Request Team Change" workspace for faculty.
///
/// Replaces the previous direct-edit dialog and routes every membership
/// change through an approval workflow. Reuses the platform's responsive
/// helpers + the existing [TeamStudentSelector] for the add/remove UX.
class TeamChangeWorkspace extends StatefulWidget {
  const TeamChangeWorkspace({
    super.key,
    required this.faculty,
    required this.team,
    required this.departmentStudents,
    required this.hasEvaluation,
    this.embedded = false,
    this.onBack,
    this.onSubmitted,
  });

  final UserModel faculty;
  final TeamModel team;
  final List<UserModel> departmentStudents;
  final bool hasEvaluation;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onSubmitted;

  @override
  State<TeamChangeWorkspace> createState() => _TeamChangeWorkspaceState();
}

class _TeamChangeWorkspaceState extends State<TeamChangeWorkspace> {
  late final Set<String> _proposedIds;
  late final Set<String> _currentIds;
  late final Map<String, UserModel> _studentsById;
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  Future<WorkflowRequest?>? _existingPendingFuture;

  @override
  void initState() {
    super.initState();
    _currentIds = widget.team.studentIds.toSet();
    _proposedIds = Set<String>.from(_currentIds);
    _studentsById = <String, UserModel>{
      for (final UserModel s in widget.departmentStudents) s.userId: s,
    };
    _reasonController.addListener(() {
      if (mounted) setState(() {});
    });
    _existingPendingFuture = _loadExistingPending();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<WorkflowRequest?> _loadExistingPending() async {
    final List<WorkflowRequest> requests = await WorkflowRequestService.listForTarget(
      entityType: 'team',
      entityId: widget.team.teamId,
    );
    for (final WorkflowRequest r in requests) {
      if (r.type == WorkflowRequestType.teamChange && r.status == WorkflowStatus.pendingApproval) {
        return r;
      }
    }
    return null;
  }

  TeamChangePayload _previewPayload() {
    final WorkflowRequest preview = TeamChangeRequestService.buildRequest(
      team: widget.team,
      faculty: widget.faculty,
      proposedStudentIds: _proposedIds,
      studentLookup: _studentsById,
      reason: _reasonController.text,
      hasEvaluation: widget.hasEvaluation,
    );
    return TeamChangePayload.fromMap(preview.payload);
  }

  List<UserModel> get _eligibleStudents {
    return widget.departmentStudents.where((UserModel student) {
      final String assignedTeamId = (student.teamId ?? '').trim();
      return assignedTeamId.isEmpty ||
          assignedTeamId == widget.team.teamId ||
          _proposedIds.contains(student.userId);
    }).toList(growable: false);
  }

  bool get _hasChanges {
    if (_proposedIds.length != _currentIds.length) return true;
    return !_proposedIds.containsAll(_currentIds);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    return _blockingReason == null;
  }

  /// Human-readable description of the next blocking validation (or `null`
  /// when the request is ready to submit). Surfaced in the sticky footer so
  /// faculty always know what to fix.
  String? get _blockingReason {
    if (_proposedIds.length < TeamChangeRequestService.minStudentsPerTeam) {
      return 'Add at least ${TeamChangeRequestService.minStudentsPerTeam} students.';
    }
    if (_proposedIds.length > TeamChangeRequestService.maxStudentsPerTeam) {
      return 'Remove a student — teams allow at most ${TeamChangeRequestService.maxStudentsPerTeam}.';
    }
    if (!_hasChanges) {
      return 'No member changes — add or remove at least one student.';
    }
    if (_reasonController.text.trim().isEmpty) {
      return 'Reason for change is required.';
    }
    return null;
  }

  void _handleBack() {
    if (widget.embedded) {
      widget.onBack?.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      TeamChangeRequestService.validateProposed(
        proposedStudentIds: _proposedIds,
        currentStudentIds: _currentIds,
        reason: _reasonController.text,
      );
      final WorkflowRequest request = TeamChangeRequestService.buildRequest(
        team: widget.team,
        faculty: widget.faculty,
        proposedStudentIds: _proposedIds,
        studentLookup: _studentsById,
        reason: _reasonController.text,
        hasEvaluation: widget.hasEvaluation,
      );
      await TeamChangeRequestService.submit(request);
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Request submitted',
        message: 'Team change request submitted for approval.',
      );
      widget.onSubmitted?.call();
      _handleBack();
    } on WorkflowRequestException catch (e) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Unable to submit request',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Submit failed',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody(context);
    if (widget.embedded) {
      return Container(color: const Color(0xFFF5F7FB), child: body);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TopBar(
          teamName: widget.team.teamName,
          submitting: _submitting,
          canSubmit: _canSubmit,
          onBack: _handleBack,
          onSubmit: _submit,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 16, compact ? 14 : 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Hero(team: widget.team, faculty: widget.faculty, hasEvaluation: widget.hasEvaluation),
                    const SizedBox(height: 14),
                    if (widget.hasEvaluation) ...<Widget>[
                      WorkflowEvaluationWarning.teamEvaluated(),
                      const SizedBox(height: 12),
                    ],
                    _buildExistingPendingBanner(),
                    _buildCurrentTeamSection(),
                    const SizedBox(height: 12),
                    _buildProposedTeamSection(),
                    const SizedBox(height: 12),
                    _buildChangeSummarySection(),
                    const SizedBox(height: 12),
                    _buildReasonSection(),
                    const SizedBox(height: 12),
                    _buildWorkflowStatusSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _Footer(
          hasChanges: _hasChanges,
          submitting: _submitting,
          canSubmit: _canSubmit,
          blockingReason: _blockingReason,
          onCancel: _handleBack,
          onSubmit: _submit,
        ),
      ],
    );
  }

  Widget _buildExistingPendingBanner() {
    return FutureBuilder<WorkflowRequest?>(
      future: _existingPendingFuture,
      builder: (BuildContext context, AsyncSnapshot<WorkflowRequest?> snapshot) {
        final WorkflowRequest? existing = snapshot.data;
        if (existing == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE4B0)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFB45309)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'A change request is already pending approval for this team. Submitting another will queue alongside the existing one.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF7C2D12), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                WorkflowStatusPill(status: existing.status, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTeamSection() {
    final List<TeamMemberSnapshot> current = widget.team.studentIds
        .map((String id) {
          final UserModel? user = _studentsById[id];
          return TeamMemberSnapshot(
            userId: id,
            displayName: user == null ? id : userDisplayName(user),
          );
        })
        .toList(growable: false);

    return RequestWorkspaceSection(
      title: 'Current team',
      subtitle: 'Members on the active team today',
      leading: _sectionIcon(AppIcons.teams, const Color(0xFF475569)),
      child: current.isEmpty
          ? const Text(
              'No members on this team.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: current
                  .map(
                    (TeamMemberSnapshot m) => TeamMemberDiffChip(
                      member: m,
                      status: TeamDiffStatus.unchanged,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildProposedTeamSection() {
    final int count = _proposedIds.length;
    final bool belowMin = count < TeamChangeRequestService.minStudentsPerTeam;
    final bool atMax = count >= TeamChangeRequestService.maxStudentsPerTeam;
    final int freeCount = _eligibleStudents
        .where((UserModel s) => !_proposedIds.contains(s.userId))
        .length;
    return RequestWorkspaceSection(
      title: 'Proposed team',
      subtitle:
          'Pick the students who should be on this team. Range: ${TeamChangeRequestService.minStudentsPerTeam}–${TeamChangeRequestService.maxStudentsPerTeam}. '
          '$freeCount student${freeCount == 1 ? '' : 's'} available to add.',
      leading: _sectionIcon(AppIcons.add, const Color(0xFF6A38FF)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: belowMin
              ? const Color(0xFFFFF7E6)
              : (atMax ? const Color(0xFFE9FAF0) : const Color(0xFFEEF2FF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: belowMin
                ? const Color(0xFFFDE4B0)
                : (atMax ? const Color(0xFFB9EBC8) : const Color(0xFFD9D3FF)),
          ),
        ),
        child: Text(
          '$count / ${TeamChangeRequestService.maxStudentsPerTeam}',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: belowMin
                ? const Color(0xFFB45309)
                : (atMax ? const Color(0xFF047857) : const Color(0xFF6A38FF)),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TeamStudentSelector(
            students: _eligibleStudents,
            selectedIds: _proposedIds,
            maxSelection: TeamChangeRequestService.maxStudentsPerTeam,
            enabled: !_submitting,
            initiallyExpanded: true,
            onChanged: (Set<String> next) => setState(() {
              _proposedIds
                ..clear()
                ..addAll(next);
            }),
          ),
          const SizedBox(height: 10),
          _buildRulesHint(belowMin: belowMin, atMax: atMax, count: count),
        ],
      ),
    );
  }

  Widget _buildRulesHint({
    required bool belowMin,
    required bool atMax,
    required int count,
  }) {
    final String message;
    final Color tone;
    final IconData icon;
    if (belowMin) {
      message =
          'Add at least ${TeamChangeRequestService.minStudentsPerTeam} students. Free students from the department appear in the list above.';
      tone = const Color(0xFFB45309);
      icon = AppIcons.workflowPendingReview;
    } else if (atMax) {
      message =
          'Team is at the maximum of ${TeamChangeRequestService.maxStudentsPerTeam} students. Remove a member to add a different student.';
      tone = const Color(0xFF047857);
      icon = AppIcons.workflowApproved;
    } else {
      message =
          'Minimum ${TeamChangeRequestService.minStudentsPerTeam} · Maximum ${TeamChangeRequestService.maxStudentsPerTeam} students. Only department students not already on another team are shown.';
      tone = const Color(0xFF64748B);
      icon = AppIcons.statusActive;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 14, color: tone),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tone),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeSummarySection() {
    final TeamChangePayload payload = _previewPayload();
    return RequestWorkspaceSection(
      title: 'Change summary',
      subtitle: 'Visual diff that the department admin will review',
      leading: _sectionIcon(Icons.compare_arrows_rounded, const Color(0xFF0EA5E9)),
      trailing: _hasChanges
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9D3FF)),
              ),
              child: Text(
                payload.changeSummary,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6A38FF),
                ),
              ),
            )
          : null,
      child: TeamMemberDiffSummary(payload: payload),
    );
  }

  Widget _buildReasonSection() {
    final bool empty = _reasonController.text.trim().isEmpty;
    return RequestWorkspaceSection(
      title: 'Reason for change',
      subtitle: 'Required · helps the department admin decide quickly.',
      leading: _sectionIcon(Icons.notes_rounded, const Color(0xFF7C3AED)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: empty ? const Color(0xFFFFF7E6) : const Color(0xFFE9FAF0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: empty ? const Color(0xFFFDE4B0) : const Color(0xFFB9EBC8),
          ),
        ),
        child: Text(
          empty ? 'Required' : 'Provided',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: empty ? const Color(0xFFB45309) : const Color(0xFF047857),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: _reasonController,
          enabled: !_submitting,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText:
                'Describe why this team change is needed (e.g. student dropped out, joining for a specific skillset...).',
            hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
        ),
      ),
    );
  }

  Widget _buildWorkflowStatusSection() {
    return RequestWorkspaceSection(
      title: 'Workflow status',
      subtitle: 'Activity timeline for this team',
      leading: _sectionIcon(Icons.timeline_rounded, const Color(0xFFEA580C)),
      child: TeamChangeHistoryTimeline(teamId: widget.team.teamId),
    );
  }

  Widget _sectionIcon(IconData icon, Color tone) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: tone),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.teamName,
    required this.submitting,
    required this.canSubmit,
    required this.onBack,
    required this.onSubmit,
  });

  final String teamName;
  final bool submitting;
  final bool canSubmit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 18, 10, compact ? 10 : 18, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFDFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF3))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Back',
            onPressed: submitting ? null : onBack,
            icon: const Icon(AppIcons.back, color: Color(0xFF334155)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Request Team Change',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          const WorkflowStatusPill(status: WorkflowStatus.draft, dense: true),
          if (!compact) ...<Widget>[
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: !canSubmit ? null : onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: const Text('Submit for Approval'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.team, required this.faculty, required this.hasEvaluation});

  final TeamModel team;
  final UserModel faculty;
  final bool hasEvaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF6F3FF), Color(0xFFEEF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2DAFB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x12273B6A), blurRadius: 16, offset: Offset(0, 8)),
        ],
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
                child: const Icon(Icons.published_with_changes_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Approval-based team modification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ContextPill(
                label: userDisplayName(faculty),
                semantic: ContextPillSemantic.user,
                icon: AppIcons.faculty,
                onTap: () => WorkspaceNavigator.openUser(context, faculty.userId),
                compact: true,
              ),
              ContextPill(
                label: team.teamName,
                semantic: ContextPillSemantic.team,
                icon: AppIcons.teams,
                onTap: () => WorkspaceNavigator.openTeam(context, team.teamId),
                compact: true,
              ),
              if (hasEvaluation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE4B0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        'Evaluated',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.hasChanges,
    required this.submitting,
    required this.canSubmit,
    required this.blockingReason,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool hasChanges;
  final bool submitting;
  final bool canSubmit;
  final String? blockingReason;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 14 : 24,
        12,
        ResponsiveHelper.isMobile(context) ? 14 : 24,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Color(0xFFE6EAF3))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Icon(
            canSubmit
                ? Icons.check_circle_outline_rounded
                : (hasChanges
                    ? Icons.error_outline_rounded
                    : Icons.compare_arrows_rounded),
            size: 16,
            color: canSubmit
                ? const Color(0xFF047857)
                : (hasChanges ? const Color(0xFFB45309) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              canSubmit
                  ? 'Ready to submit · workflow status will move to Pending Approval.'
                  : (blockingReason ??
                      'No member changes — add or remove students to enable submission.'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: canSubmit
                    ? const Color(0xFF047857)
                    : (hasChanges ? const Color(0xFFB45309) : const Color(0xFF64748B)),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: submitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: canSubmit ? onSubmit : null,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Submit Request'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              backgroundColor: const Color(0xFF6A38FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny façade around the existing [FacultyTeamInsight] so callers can ask the
/// "should I show evaluation warnings?" question without depending on
/// implementation details.
class TeamChangeWorkspaceController {
  TeamChangeWorkspaceController._();

  static bool hasEvaluation(FacultyTeamInsight insight) => insight.hasEvaluation;
}
