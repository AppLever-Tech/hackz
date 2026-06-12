import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../utils/common_helpers.dart';
import '../models/team_change_request.dart';
import '../models/workflow_request.dart';
import '../models/workflow_status.dart';
import '../services/workflow_request_service.dart';
import 'workflow_status_pill.dart';

/// Compact "audit trail" timeline of every team change request ever filed for
/// a given team. Rendered inside the team workspace body so faculty and dept
/// admins share a single history surface.
class TeamChangeHistoryTimeline extends StatefulWidget {
  const TeamChangeHistoryTimeline({super.key, required this.teamId});

  final String teamId;

  @override
  State<TeamChangeHistoryTimeline> createState() => _TeamChangeHistoryTimelineState();
}

class _TeamChangeHistoryTimelineState extends State<TeamChangeHistoryTimeline> {
  late Future<List<WorkflowRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WorkflowRequest>> _load() {
    return WorkflowRequestService.listForTarget(
      entityType: 'team',
      entityId: widget.teamId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Team change history',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<WorkflowRequest>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<WorkflowRequest>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HistoryEmpty(message: 'Loading history…');
            }
            if (snapshot.hasError) {
              return _HistoryEmpty(message: 'Unable to load history: ${snapshot.error}');
            }
            final List<WorkflowRequest> requests = snapshot.data ?? const <WorkflowRequest>[];
            if (requests.isEmpty) {
              return const _HistoryEmpty(
                message: 'No team change requests have been filed yet.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < requests.length; i++)
                  _HistoryTile(
                    request: requests[i],
                    isLast: i == requests.length - 1,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.request, required this.isLast});

  final WorkflowRequest request;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final TeamChangePayload? payload = TeamChangePayload.fromRequest(request);
    final List<_TimelineLine> lines = _resolveLines(payload);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(AppIcons.teams, size: 14, color: Color(0xFF57629A)),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  color: const Color(0xFFE6EAF3),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        request.summary.isEmpty ? request.title : request.summary,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    WorkflowStatusPill(status: request.status, dense: true),
                  ],
                ),
                const SizedBox(height: 4),
                ...lines.map(
                  (_TimelineLine line) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: line.color ?? const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${request.requestedByName.isEmpty ? 'Faculty' : request.requestedByName} · ${formatDateTime(request.resolvedAt)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (request.adminComments.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    '“${request.adminComments.trim()}”',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineLine> _resolveLines(TeamChangePayload? payload) {
    final List<_TimelineLine> lines = <_TimelineLine>[];
    if (payload != null) {
      for (final TeamMemberSnapshot m in payload.addedMembers) {
        lines.add(_TimelineLine(
          text: '${_nameOrId(m)} added',
          color: const Color(0xFF047857),
        ));
      }
      for (final TeamMemberSnapshot m in payload.removedMembers) {
        lines.add(_TimelineLine(
          text: '${_nameOrId(m)} removed',
          color: const Color(0xFFB91C1C),
        ));
      }
    }
    if (request.status == WorkflowStatus.approved && request.approvedBy.isNotEmpty) {
      lines.add(const _TimelineLine(text: 'Approved by Dept Admin'));
    } else if (request.status == WorkflowStatus.rejected && request.rejectedBy.isNotEmpty) {
      lines.add(const _TimelineLine(text: 'Rejected by Dept Admin'));
    }
    return lines;
  }

  String _nameOrId(TeamMemberSnapshot m) =>
      m.displayName.trim().isEmpty ? m.userId : m.displayName.trim();
}

class _TimelineLine {
  const _TimelineLine({required this.text, this.color});
  final String text;
  final Color? color;
}
