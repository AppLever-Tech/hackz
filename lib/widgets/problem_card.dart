import 'package:flutter/material.dart';

import '../models/problem_model.dart';

class ProblemCard extends StatefulWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    this.canEdit = false,
    this.canToggleActive = false,
    this.onEdit,
    this.onToggleActive,
    this.onViewAttachments,
    this.initiallyExpanded = false,
  });

  final ProblemModel problem;
  final bool canEdit;
  final bool canToggleActive;
  final ValueChanged<ProblemModel>? onEdit;
  final ValueChanged<ProblemModel>? onToggleActive;
  final ValueChanged<ProblemModel>? onViewAttachments;
  final bool initiallyExpanded;

  @override
  State<ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<ProblemCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTags = widget.problem.tags.take(3).toList(growable: false);
    final extraTagCount = widget.problem.tags.length - visibleTags.length;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildProblemNumberBadge(theme),
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.problem.title.trim().isEmpty ? 'Untitled Problem' : widget.problem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    widget.problem.departmentDisplayName.trim().isEmpty
                        ? '-'
                        : widget.problem.departmentDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('•', style: TextStyle(color: Colors.grey.shade500)),
                ),
                _buildStatusIndicator(theme),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                ...visibleTags.map(_buildTagPill),
                if (extraTagCount > 0) _buildMoreTagsPill(extraTagCount),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.attach_file, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text(
                  '${widget.problem.attachments.length}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.problem.description.trim().isEmpty
                          ? 'No description provided.'
                          : widget.problem.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Created by: ${widget.problem.createdBy.isEmpty ? '-' : widget.problem.createdBy}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDate(widget.problem.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onViewAttachments == null
                          ? null
                          : () => widget.onViewAttachments!(widget.problem),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Attachments'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (widget.canEdit || widget.canToggleActive) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          if (widget.canEdit)
                            OutlinedButton.icon(
                              onPressed: widget.onEdit == null
                                  ? null
                                  : () => widget.onEdit!(widget.problem),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (widget.canEdit && widget.canToggleActive) const SizedBox(width: 8),
                          if (widget.canToggleActive)
                            OutlinedButton.icon(
                              onPressed: widget.onToggleActive == null
                                  ? null
                                  : () => widget.onToggleActive!(widget.problem),
                              icon: Icon(
                                widget.problem.isActive
                                    ? Icons.toggle_on_outlined
                                    : Icons.toggle_off_outlined,
                                size: 16,
                              ),
                              label: Text(widget.problem.isActive ? 'Set Inactive' : 'Set Active'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemNumberBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.problem.problemNumber.trim().isEmpty ? 'N/A' : widget.problem.problemNumber,
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2E43C6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final isActive = widget.problem.isActive;
    final dotColor = isActive ? const Color(0xFF1AAE60) : const Color(0xFFD34A4A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTagPill(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildMoreTagsPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
