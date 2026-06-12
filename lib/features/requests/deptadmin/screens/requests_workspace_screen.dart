import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../user/models/user_model.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../models/workflow_request.dart';
import '../../models/workflow_request_type.dart';
import '../../models/workflow_status.dart';
import '../../services/workflow_request_service.dart';
import 'request_list_pane.dart';
import 'request_review_pane.dart';

/// Generic Department Admin "Request Management Workspace".
///
/// Split-pane workspace that lists every request in the department and
/// surfaces detail + approve/reject actions for the selected request. The
/// architecture is intentionally type-agnostic; new request types light up
/// automatically once they appear in [WorkflowRequestType] (and have a
/// payload renderer in [RequestReviewPane]).
class RequestsWorkspaceScreen extends StatefulWidget {
  const RequestsWorkspaceScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<RequestsWorkspaceScreen> createState() => _RequestsWorkspaceScreenState();
}

class _RequestsWorkspaceScreenState extends State<RequestsWorkspaceScreen> {
  late Future<List<WorkflowRequest>> _future;
  WorkflowRequestFilter _filter = const WorkflowRequestFilter(
    statuses: <WorkflowStatus>{WorkflowStatus.pendingApproval},
  );
  String? _selectedRequestId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WorkflowRequest>> _load() {
    return WorkflowRequestService.listForDepartment(
      orgId: widget.user.orgId,
      departmentCode: widget.user.departmentCode,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _onRequestUpdated(WorkflowRequest updated) {
    _refresh();
    setState(() => _selectedRequestId = updated.requestId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkflowRequest>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<WorkflowRequest>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Unable to load requests: ${snapshot.error}'),
            ),
          );
        }
        final List<WorkflowRequest> all = snapshot.data ?? const <WorkflowRequest>[];
        final List<WorkflowRequest> filtered =
            all.where(_filter.matches).toList(growable: false);

        final WorkflowRequest? selected =
            _resolveSelected(filtered.isEmpty ? all : filtered);

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact =
                ResponsiveHelper.isMobile(context) || constraints.maxWidth < 880;
            if (isCompact) {
              return _buildStacked(context, all, filtered, selected);
            }
            return _buildSplit(context, all, filtered, selected);
          },
        );
      },
    );
  }

  WorkflowRequest? _resolveSelected(List<WorkflowRequest> source) {
    if (source.isEmpty) return null;
    if (_selectedRequestId != null) {
      for (final WorkflowRequest r in source) {
        if (r.requestId == _selectedRequestId) return r;
      }
    }
    return source.first;
  }

  Widget _buildSplit(
    BuildContext context,
    List<WorkflowRequest> all,
    List<WorkflowRequest> filtered,
    WorkflowRequest? selected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 360,
            child: RequestListPane(
              allRequests: all,
              filteredRequests: filtered,
              filter: _filter,
              selectedRequestId: selected?.requestId,
              onFilterChanged: (WorkflowRequestFilter next) {
                setState(() => _filter = next);
              },
              onSelected: (WorkflowRequest r) {
                setState(() => _selectedRequestId = r.requestId);
              },
              onRefresh: _refresh,
            ),
          ),
          Container(width: 1, color: const Color(0xFFE6EAF3)),
          Expanded(
            child: selected == null
                ? const _EmptyReviewState()
                : RequestReviewPane(
                    request: selected,
                    approver: widget.user,
                    onActionComplete: _onRequestUpdated,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStacked(
    BuildContext context,
    List<WorkflowRequest> all,
    List<WorkflowRequest> filtered,
    WorkflowRequest? selected,
  ) {
    if (_selectedRequestId != null && selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => setState(() => _selectedRequestId = null),
                  icon: const Icon(AppIcons.back),
                  tooltip: 'Back to requests',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Request review',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RequestReviewPane(
              request: selected,
              approver: widget.user,
              onActionComplete: _onRequestUpdated,
            ),
          ),
        ],
      );
    }
    return RequestListPane(
      allRequests: all,
      filteredRequests: filtered,
      filter: _filter,
      selectedRequestId: null,
      onFilterChanged: (WorkflowRequestFilter next) {
        setState(() => _filter = next);
      },
      onSelected: (WorkflowRequest r) {
        setState(() => _selectedRequestId = r.requestId);
      },
      onRefresh: _refresh,
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inbox_rounded, size: 28, color: Color(0xFF6A38FF)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No requests to review',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'When faculty submit approval requests, you will see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
