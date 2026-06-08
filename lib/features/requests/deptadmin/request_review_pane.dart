import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../user/models/user_model.dart';
import '../../../responsive/responsive_dialog.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../shared/feedback/feedback.dart';
import '../../../utils/common_helpers.dart';
import '../../../widgets/responsive/responsive_alert_dialog.dart';
import '../../../workspace/workspace.dart';
import '../models/team_change_request.dart';
import '../models/workflow_request.dart';
import '../models/workflow_request_type.dart';
import '../models/workflow_status.dart';
import '../services/team_change_request_service.dart';
import '../services/workflow_request_service.dart';
import '../widgets/request_workspace_section.dart';
import '../widgets/team_member_diff_view.dart';
import '../widgets/workflow_evaluation_warning.dart';
import '../widgets/workflow_status_pill.dart';

/// Right pane of the dept-admin requests workspace. Renders a type-aware
/// review surface and the approve / reject actions.
class RequestReviewPane extends StatefulWidget {
  const RequestReviewPane({
    super.key,
    required this.request,
    required this.approver,
    required this.onActionComplete,
  });

  final WorkflowRequest request;
  final UserModel approver;
  final ValueChanged<WorkflowRequest> onActionComplete;

  @override
  State<RequestReviewPane> createState() => _RequestReviewPaneState();
}

class _RequestReviewPaneState extends State<RequestReviewPane> {
  bool _processing = false;

  Future<void> _approve() async {
    if (_processing) return;
    final WorkflowRequest request = widget.request;
    if (request.status.isTerminal) return;
    final bool? confirmed = await _confirmApprove(context, request);
    if (confirmed != true) return;
    await _runAction(() async {
      WorkflowRequest updated;
      switch (request.type) {
        case WorkflowRequestType.teamChange:
          updated = await TeamChangeRequestService.approve(
            request: request,
            approver: widget.approver,
          );
        default:
          updated = await WorkflowRequestService.markApproved(
            request: request,
            approvedByUserId: widget.approver.userId,
          );
      }
      if (!mounted) return;
      widget.onActionComplete(updated);
      FeedbackService.showSuccess(
        context,
        title: 'Request approved',
        message: '${request.type.label} approved.',
      );
    });
  }

  Future<void> _reject() async {
    if (_processing) return;
    final WorkflowRequest request = widget.request;
    if (request.status.isTerminal) return;
    final String? reason = await _promptForRejectionReason(context);
    if (reason == null || reason.trim().isEmpty) return;
    await _runAction(() async {
      WorkflowRequest updated;
      switch (request.type) {
        case WorkflowRequestType.teamChange:
          updated = await TeamChangeRequestService.reject(
            request: request,
            approver: widget.approver,
            comments: reason,
          );
        default:
          updated = await WorkflowRequestService.reject(
            request: request,
            rejectedByUserId: widget.approver.userId,
            comments: reason,
          );
      }
      if (!mounted) return;
      widget.onActionComplete(updated);
      FeedbackService.showInfo(
        context,
        title: 'Request rejected',
        message: '${request.type.label} rejected.',
      );
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _processing = true);
    try {
      await action();
    } on WorkflowRequestException catch (e) {
      if (!mounted) return;
      FeedbackService.showWarning(
        context,
        title: 'Action blocked',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Action failed',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkflowRequest request = widget.request;
    final bool compact = ResponsiveHelper.isMobile(context);
    return Container(
      color: const Color(0xFFF5F7FB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(compact ? 14 : 22, 16, compact ? 14 : 22, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ReviewHero(request: request),
                      const SizedBox(height: 14),
                      _buildTypeSpecificSections(request),
                      const SizedBox(height: 12),
                      _buildReasonSection(request),
                      if (request.adminComments.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildAdminCommentsSection(request),
                      ],
                      const SizedBox(height: 12),
                      _buildAuditSection(request),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ActionBar(
            request: request,
            processing: _processing,
            onApprove: _approve,
            onReject: _reject,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificSections(WorkflowRequest request) {
    switch (request.type) {
      case WorkflowRequestType.teamChange:
        final TeamChangePayload? payload = TeamChangePayload.fromRequest(request);
        if (payload == null) {
          return RequestWorkspaceSection(
            title: 'Team change payload',
            child: const Text(
              'Payload data is missing for this request.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (payload.hasEvaluation) ...<Widget>[
              WorkflowEvaluationWarning.teamEvaluated(),
              const SizedBox(height: 12),
            ],
            RequestWorkspaceSection(
              title: 'Visual team diff',
              subtitle: 'Compare the active team with the proposed change',
              leading: _sectionIcon(Icons.compare_arrows_rounded, const Color(0xFF6A38FF)),
              trailing: payload.hasChanges
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TeamMemberDiffView(
                    currentMembers: payload.currentMembers,
                    proposedMembers: payload.proposedMembers,
                  ),
                  const SizedBox(height: 10),
                  TeamMemberDiffSummary(payload: payload),
                ],
              ),
            ),
          ],
        );
      default:
        return RequestWorkspaceSection(
          title: '${request.type.label} payload',
          subtitle: request.type.description,
          child: Text(
            'Review surface for ${request.type.label} is not implemented yet — '
            'the workflow status and audit trail will still work generically.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        );
    }
  }

  Widget _buildReasonSection(WorkflowRequest request) {
    return RequestWorkspaceSection(
      title: 'Reason for change',
      subtitle: 'Submitted by the requesting faculty',
      leading: _sectionIcon(Icons.notes_rounded, const Color(0xFF7C3AED)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6EAF3)),
        ),
        child: Text(
          request.reason.trim().isEmpty ? 'No reason provided.' : request.reason.trim(),
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), height: 1.45),
        ),
      ),
    );
  }

  Widget _buildAdminCommentsSection(WorkflowRequest request) {
    final bool rejected = request.status == WorkflowStatus.rejected;
    final Color tone = rejected ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    return RequestWorkspaceSection(
      title: rejected ? 'Rejection comments' : 'Approval comments',
      subtitle: 'Visible to the requesting faculty',
      leading: _sectionIcon(
        rejected ? AppIcons.statusRejected : AppIcons.workflowApproved,
        tone,
      ),
      tone: tone,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: rejected ? const Color(0xFFFEECEC) : const Color(0xFFE9FAF0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rejected ? const Color(0xFFF8C4C4) : const Color(0xFFB9EBC8)),
        ),
        child: Text(
          request.adminComments.trim(),
          style: TextStyle(fontSize: 12.5, color: tone, fontWeight: FontWeight.w600, height: 1.45),
        ),
      ),
    );
  }

  Widget _buildAuditSection(WorkflowRequest request) {
    final List<_AuditEvent> events = <_AuditEvent>[
      _AuditEvent(
        icon: Icons.send_rounded,
        title: 'Submitted',
        detail:
            '${request.requestedByName.isEmpty ? 'Faculty' : request.requestedByName} · ${formatDateTime(request.requestedAt)}',
        tone: const Color(0xFF6A38FF),
      ),
      if (request.status == WorkflowStatus.approved && request.approvedAt != null)
        _AuditEvent(
          icon: AppIcons.workflowApproved,
          title: 'Approved',
          detail:
              '${request.approvedBy.isEmpty ? 'Department admin' : request.approvedBy} · ${formatDateTime(request.approvedAt!)}',
          tone: const Color(0xFF047857),
        ),
      if (request.status == WorkflowStatus.rejected && request.rejectedAt != null)
        _AuditEvent(
          icon: AppIcons.statusRejected,
          title: 'Rejected',
          detail:
              '${request.rejectedBy.isEmpty ? 'Department admin' : request.rejectedBy} · ${formatDateTime(request.rejectedAt!)}',
          tone: const Color(0xFFB91C1C),
        ),
    ];
    return RequestWorkspaceSection(
      title: 'Audit trail',
      subtitle: 'Workflow events for this request',
      leading: _sectionIcon(Icons.timeline_rounded, const Color(0xFF0EA5E9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: events.map(_AuditTile.new).toList(growable: false),
      ),
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

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({required this.request});

  final WorkflowRequest request;

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2DAFB)),
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
                child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      request.type.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.title.isEmpty ? request.type.label : request.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              WorkflowStatusPill(status: request.status),
            ],
          ),
          if (request.summary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              request.summary,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              if (request.requestedBy.isNotEmpty)
                ContextPill(
                  label: request.requestedByName.isEmpty ? 'Requester' : request.requestedByName,
                  semantic: ContextPillSemantic.user,
                  icon: AppIcons.faculty,
                  onTap: () => WorkspaceNavigator.openUser(context, request.requestedBy),
                  compact: true,
                ),
              if (request.targetEntityType == 'team' && request.targetEntityId.isNotEmpty)
                ContextPill(
                  label: _teamLabel(request),
                  semantic: ContextPillSemantic.team,
                  icon: AppIcons.teams,
                  onTap: () => WorkspaceNavigator.openTeam(context, request.targetEntityId),
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _teamLabel(WorkflowRequest request) {
    final TeamChangePayload? payload = TeamChangePayload.fromRequest(request);
    if (payload != null && payload.teamName.isNotEmpty) return payload.teamName;
    return 'Team';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.request,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final WorkflowRequest request;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bool actionable = !request.status.isTerminal;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 14 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 14 : 22,
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
            actionable ? Icons.gavel_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: actionable ? const Color(0xFF6A38FF) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              actionable
                  ? 'Decide on this request — approval will apply changes immediately.'
                  : 'This request is ${request.status.label.toLowerCase()} — no further action is needed.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: actionable ? const Color(0xFF6A38FF) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: actionable && !processing ? onReject : null,
            icon: const Icon(AppIcons.statusRejected, size: 16),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFF8C4C4)),
              minimumSize: const Size(0, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: actionable && !processing ? onApprove : null,
            icon: processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(AppIcons.workflowApproved, size: 16),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEvent {
  const _AuditEvent({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tone;
}

class _AuditTile extends StatelessWidget {
  const _AuditTile(this.event);

  final _AuditEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: event.tone.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.icon, size: 14, color: event.tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: event.tone),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirmApprove(BuildContext context, WorkflowRequest request) {
  return FeedbackService.showConfirmation(
    context,
    title: 'Approve ${request.type.label.toLowerCase()}?',
    message: 'This will apply ${request.summary.isEmpty ? 'the proposed changes' : request.summary} to the active record.',
    confirmLabel: 'Approve',
    cancelLabel: 'Cancel',
  );
}

Future<String?> _promptForRejectionReason(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => ResponsiveAlertDialog(
      title: const Text('Reject request'),
      widthPreset: DialogWidthPreset.compact,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'A reason is required so faculty understand why the request was rejected.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Describe the rejection reason…',
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final String value = controller.text.trim();
            if (value.isEmpty) return;
            Navigator.of(ctx).pop(value);
          },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}
