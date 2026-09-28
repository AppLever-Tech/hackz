import 'package:flutter/material.dart';

import '../../../features/user/models/user_model.dart';
import '../../../utils/common_helpers.dart';

class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onChanged,
    required this.orgId,
    required this.departmentCode,
    this.maxSelection = 4,
    this.placeholder = 'Select Team Members',
    this.enabled = true,
  });

  final List<UserModel> members;
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

  List<UserModel> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.members.where((member) {
      if (member.orgId.trim() != widget.orgId.trim()) return false;
      if (member.departmentCode.trim().toUpperCase() != widget.departmentCode.trim().toUpperCase()) return false;
      final name = '${member.firstName} ${member.lastName}'.trim().toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query) || member.email.toLowerCase().contains(query);
    });
    return sortUsersByDisplayName(filtered);
  }

  void _toggleSelection(UserModel member) {
    final next = Set<String>.from(widget.selectedIds);
    final selected = next.contains(member.userId);
    if (selected) {
      next.remove(member.userId);
      widget.onChanged(next);
      _overlayEntry?.markNeedsBuild();
      return;
    }
    if (next.length >= widget.maxSelection) return;
    next.add(member.userId);
    widget.onChanged(next);
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildFollowerPanel() {
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = renderBox?.size ?? const Size(480, 44);
    final members = _filteredMembers;
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
                    hintText: 'Search team members',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: members.isEmpty
                      ? const Center(child: Text('No team members found'))
                      : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isSelected = widget.selectedIds.contains(member.userId);
                            final atLimit = !isSelected && widget.selectedIds.length >= widget.maxSelection;
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: isSelected,
                              onChanged: atLimit ? null : (_) => _toggleSelection(member),
                              title: Text('${member.firstName} ${member.lastName}'.trim()),
                              subtitle: Text(member.email, maxLines: 1, overflow: TextOverflow.ellipsis),
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
