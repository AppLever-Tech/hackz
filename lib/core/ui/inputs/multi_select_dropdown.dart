import 'package:flutter/material.dart';

import '../../../features/user/models/user_model.dart';
import '../../../utils/common_helpers.dart';

class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({
    super.key,
    required this.students,
    required this.selectedIds,
    required this.onChanged,
    required this.orgId,
    required this.departmentCode,
    this.maxSelection = 4,
    this.placeholder = 'Select Students',
    this.enabled = true,
  });

  final List<UserModel> students;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final String orgId;
  final String departmentCode;
  final int maxSelection;
  final String placeholder;
  final bool enabled;

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay(notify: false);
    _searchController.dispose();
    super.dispose();
  }

  bool get _isOpen => _overlayEntry != null;

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          _buildFollowerPanel(),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _removeOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted) setState(() {});
  }

  List<UserModel> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.students.where((student) {
      if (student.orgId.trim() != widget.orgId.trim()) return false;
      if (student.departmentCode.trim().toUpperCase() != widget.departmentCode.trim().toUpperCase()) return false;
      final name = '${student.firstName} ${student.lastName}'.trim().toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query) || student.email.toLowerCase().contains(query);
    });
    return sortUsersByDisplayName(filtered);
  }

  void _toggleSelection(UserModel student) {
    final next = Set<String>.from(widget.selectedIds);
    final selected = next.contains(student.userId);
    if (selected) {
      next.remove(student.userId);
      widget.onChanged(next);
      _overlayEntry?.markNeedsBuild();
      return;
    }
    if (next.length >= widget.maxSelection) return;
    next.add(student.userId);
    widget.onChanged(next);
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildFollowerPanel() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = renderBox?.size ?? const Size(480, 44);
    final students = _filteredStudents;
    return Positioned(
      width: fieldSize.width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, fieldSize.height + 6),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3E6F0)),
            ),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _overlayEntry?.markNeedsBuild(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Search students',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text('No students found'))
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final isSelected = widget.selectedIds.contains(student.userId);
                            final atLimit = !isSelected && widget.selectedIds.length >= widget.maxSelection;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: isSelected,
                              onChanged: atLimit ? null : (_) => _toggleSelection(student),
                              title: Text('${student.firstName} ${student.lastName}'.trim()),
                              subtitle: Text(student.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text('${widget.selectedIds.length} / ${widget.maxSelection} selected'),
                    const Spacer(),
                    FilledButton(
                      onPressed: _removeOverlay,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedIds.length;
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        key: _fieldKey,
        onTap: widget.enabled ? _toggleOverlay : null,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: Icon(widget.enabled ? (_isOpen ? Icons.expand_less : Icons.expand_more) : Icons.lock_outline),
          ),
          child: Text(selectedCount == 0 ? widget.placeholder : '$selectedCount selected'),
        ),
      ),
    );
  }
}
