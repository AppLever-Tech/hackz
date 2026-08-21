import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../utils/common_helpers.dart';
import '../../models/workflow_request.dart';
import '../../models/workflow_request_type.dart';
import '../../models/workflow_status.dart';
import '../../services/workflow_request_service.dart';
import '../../widgets/workflow_status_pill.dart';

/// Left pane of the dept-admin requests workspace: search + filters + list.
class RequestListPane extends StatefulWidget {
  const RequestListPane({
    super.key,
    required this.allRequests,
    required this.filteredRequests,
    required this.filter,
    required this.selectedRequestId,
    required this.onFilterChanged,
    required this.onSelected,
    required this.onRefresh,
  });

  final List<WorkflowRequest> allRequests;
  final List<WorkflowRequest> filteredRequests;
  final WorkflowRequestFilter filter;
  final String? selectedRequestId;
  final ValueChanged<WorkflowRequestFilter> onFilterChanged;
  final ValueChanged<WorkflowRequest> onSelected;
  final VoidCallback onRefresh;

  @override
  State<RequestListPane> createState() => _RequestListPaneState();
}

class _RequestListPaneState extends State<RequestListPane> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.filter.search;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleStatus(WorkflowStatus status) {
    final Set<WorkflowStatus> next = Set<WorkflowStatus>.from(widget.filter.statuses);
    if (next.contains(status)) {
      next.remove(status);
    } else {
      next.add(status);
    }
    widget.onFilterChanged(widget.filter.copyWith(statuses: next));
  }

  void _toggleType(WorkflowRequestType type) {
    final Set<WorkflowRequestType> next = Set<WorkflowRequestType>.from(widget.filter.types);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    widget.onFilterChanged(widget.filter.copyWith(types: next));
  }

  void _onSearch(String value) {
    widget.onFilterChanged(widget.filter.copyWith(search: value));
  }

  int _countByStatus(WorkflowStatus status) {
    return widget.allRequests.where((WorkflowRequest r) => r.status == status).length;
  }

  Set<WorkflowRequestType> get _availableTypes {
    final Set<WorkflowRequestType> types = <WorkflowRequestType>{};
    for (final WorkflowRequest r in widget.allRequests) {
      types.add(r.type);
    }
    return types;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(),
          _buildSearch(),
          if (_filtersExpanded) _buildFilters(),
          const Divider(height: 1, color: Color(0xFFE6EAF3)),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 6),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inbox_rounded, size: 16, color: Color(0xFF6A38FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Requests',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 1),
                Text(
                  '${widget.filteredRequests.length} shown · ${widget.allRequests.length} total',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: widget.onRefresh,
            icon: const Icon(AppIcons.refresh, size: 18),
            color: const Color(0xFF6A38FF),
          ),
          IconButton(
            tooltip: _filtersExpanded ? 'Hide filters' : 'Show filters',
            onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
            icon: Icon(
              _filtersExpanded ? Icons.filter_alt_off_outlined : Icons.filter_alt_outlined,
              size: 18,
            ),
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search by team, team leader, reason…',
          prefixIcon: const Icon(AppIcons.search, size: 18),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.3),
          ),
        ),
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }

  Widget _buildFilters() {
    final Set<WorkflowRequestType> availableTypes = _availableTypes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _FilterLabel('Workflow status'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: WorkflowStatus.values.map((WorkflowStatus s) {
              final bool selected = widget.filter.statuses.contains(s);
              final int count = _countByStatus(s);
              return _FilterChip(
                label: '${s.label} · $count',
                selected: selected,
                onTap: () => _toggleStatus(s),
              );
            }).toList(growable: false),
          ),
          if (availableTypes.length > 1) ...<Widget>[
            const SizedBox(height: 10),
            const _FilterLabel('Request type'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: availableTypes
                  .map((WorkflowRequestType t) {
                    final bool selected = widget.filter.types.contains(t);
                    return _FilterChip(
                      label: t.label,
                      selected: selected,
                      onTap: () => _toggleType(t),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    if (widget.filteredRequests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              widget.allRequests.isEmpty
                  ? 'No requests in your department yet.'
                  : 'No requests match your filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      itemCount: widget.filteredRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (BuildContext context, int index) {
        final WorkflowRequest request = widget.filteredRequests[index];
        final bool selected = request.requestId == widget.selectedRequestId;
        return _RequestListTile(
          request: request,
          selected: selected,
          onTap: () => widget.onSelected(request),
        );
      },
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF6A38FF) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _RequestListTile extends StatelessWidget {
  const _RequestListTile({
    required this.request,
    required this.selected,
    required this.onTap,
  });

  final WorkflowRequest request;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF6A38FF) : const Color(0xFFE6EAF3),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      request.title.isEmpty ? request.type.label : request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  WorkflowStatusPill(status: request.status, dense: true),
                ],
              ),
              if (request.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  request.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A38FF),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Icon(AppIcons.student, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.requestedByName.isEmpty ? 'Team Leader' : request.requestedByName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDateTime(request.resolvedAt),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
