import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../workspace/workspace.dart';

/// Searchable inline student picker with selected user workspace pills.
class TeamStudentSelector extends StatefulWidget {
  const TeamStudentSelector({
    super.key,
    required this.students,
    required this.selectedIds,
    required this.onChanged,
    required this.maxSelection,
    this.enabled = true,
    this.searchThreshold = 6,
    this.initiallyExpanded,
  });

  static const double listMaxHeight = 200;

  final List<UserModel> students;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final int maxSelection;
  final bool enabled;
  final int searchThreshold;

  /// Optional override for the initial expanded state of the inline picker.
  /// When `null` (default) the picker auto-opens only when nothing is selected
  /// yet — which matches the create-team UX. Pass `true` in flows like
  /// "Request Team Change" where the team already has members but the user
  /// still needs the picker visible to add/swap students.
  final bool? initiallyExpanded;

  @override
  State<TeamStudentSelector> createState() => _TeamStudentSelectorState();
}

class _TeamStudentSelectorState extends State<TeamStudentSelector> {
  final TextEditingController _searchController = TextEditingController();
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ?? widget.selectedIds.isEmpty;
  }

  bool get _showSearch => widget.students.length > widget.searchThreshold;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredStudents {
    final String query = _searchController.text.trim().toLowerCase();
    final Iterable<UserModel> source = widget.students.where((UserModel s) {
      if (query.isEmpty) return true;
      final String name = userDisplayName(s).toLowerCase();
      return name.contains(query) || s.email.toLowerCase().contains(query);
    });
    return sortUsersByDisplayName(source);
  }

  void _toggleStudent(UserModel student) {
    final Set<String> next = Set<String>.from(widget.selectedIds);
    if (next.contains(student.userId)) {
      next.remove(student.userId);
    } else {
      if (next.length >= widget.maxSelection) return;
      next.add(student.userId);
    }
    widget.onChanged(next);
  }

  void _removeStudent(String userId) {
    final Set<String> next = Set<String>.from(widget.selectedIds)..remove(userId);
    widget.onChanged(next);
  }

  UserModel? _studentById(String id) {
    for (final UserModel student in widget.students) {
      if (student.userId == id) return student;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<UserModel> selected = widget.selectedIds
        .map(_studentById)
        .whereType<UserModel>()
        .toList(growable: false);
    final List<UserModel> sortedSelected = sortUsersByDisplayName(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (sortedSelected.isEmpty)
          const Text(
            'No students selected yet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedSelected.map((UserModel student) => _selectedPill(context, student)).toList(growable: false),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: widget.enabled ? () => setState(() => _expanded = !_expanded) : null,
            icon: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.expand_more, size: 20),
            ),
            label: Text(_expanded ? 'Hide student list' : 'Add students'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6A38FF),
              side: const BorderSide(color: Color(0xFFD9CBFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildPickerPanel(context),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  Widget _selectedPill(BuildContext context, UserModel student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ContextPill(
          label: userDisplayName(student),
          semantic: ContextPillSemantic.user,
          icon: AppIcons.student,
          onTap: () => WorkspaceNavigator.openUser(context, student.userId),
          compact: true,
        ),
        if (widget.enabled)
          IconButton(
            onPressed: () => _removeStudent(student.userId),
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Remove student',
            color: const Color(0xFF64748B),
          ),
      ],
    );
  }

  Widget _buildPickerPanel(BuildContext context) {
    final List<UserModel> visible = _filteredStudents;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_showSearch) ...<Widget>[
            TextField(
              controller: _searchController,
              enabled: widget.enabled,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search students',
                prefixIcon: const Icon(AppIcons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFCFDFF),
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
            ),
            const SizedBox(height: 8),
          ],
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No students match your search.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: TeamStudentSelector.listMaxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (BuildContext context, int index) {
                  final UserModel student = visible[index];
                  return _studentPickerTile(context, student);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _studentPickerTile(BuildContext context, UserModel student) {
    final bool selected = widget.selectedIds.contains(student.userId);
    final bool atLimit = !selected && widget.selectedIds.length >= widget.maxSelection;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled && !atLimit ? () => _toggleStudent(student) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: selected ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      userDisplayName(student),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? const Color(0xFF4C1D95) : const Color(0xFF0F172A),
                      ),
                    ),
                    if (student.email.trim().isNotEmpty)
                      Text(
                        student.email.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
