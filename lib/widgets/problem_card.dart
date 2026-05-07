import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/problem_model.dart';

class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    this.canEdit = false,
    this.canDelete = false,
    this.onEdit,
    this.onDelete,
    this.onViewAttachments,
    this.onViewDetails,
    this.totalIdeas = 0,
    this.evaluatedCount = 0,
    this.approvedCount = 0,
    this.attachmentCount = 0,
    this.initiallyExpanded = false,
  });

  final ProblemModel problem;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<ProblemModel>? onEdit;
  final ValueChanged<ProblemModel>? onDelete;
  final ValueChanged<ProblemModel>? onViewAttachments;
  final ValueChanged<ProblemModel>? onViewDetails;
  final int totalIdeas;
  final int evaluatedCount;
  final int approvedCount;
  final int attachmentCount;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTags = problem.tags.take(3).toList(growable: false);
    final extraTagCount = problem.tags.length - visibleTags.length;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onViewDetails == null ? null : () => onViewDetails!(problem),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
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
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: onEdit == null ? null : () => onEdit!(problem),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (canEdit && canDelete) const SizedBox(width: 8),
                if (canDelete)
                  OutlinedButton.icon(
                    onPressed: onDelete == null ? null : () => onDelete!(problem),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Row(
                    children: <Widget>[
                      Icon(AppIcons.problems, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: problem.isActive ? 'Active' : 'Inactive',
                        child: Icon(
                          problem.isActive ? AppIcons.statusActive : AppIcons.statusInactive,
                          size: 12,
                          color: problem.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildCompactProgress(theme),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(AppIcons.departments, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          problem.departmentDisplayName.trim().isEmpty ? '-' : problem.departmentDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _inlineAttachmentCount(
                        icon: AppIcons.attachments,
                        tooltip: 'Attachments',
                        count: attachmentCount,
                        color: const Color(0xFF334155),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _inlineStat(
                  icon: AppIcons.ideas,
                  tooltip: 'Total Ideas',
                  count: totalIdeas,
                  color: const Color(0xFF4A67FF),
                ),
                const SizedBox(width: 12),
                _inlineStat(
                  icon: AppIcons.statusEvaluated,
                  tooltip: 'Evaluated',
                  count: evaluatedCount,
                  color: const Color(0xFF7B1FA2),
                ),
                const SizedBox(width: 12),
                _inlineStat(
                  icon: AppIcons.statusApproved,
                  tooltip: 'Approved',
                  count: approvedCount,
                  color: const Color(0xFF2E7D32),
                ),
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
          ],
        ),
      ),
    );
  }

  Widget _inlineAttachmentCount({
    required IconData icon,
    required String tooltip,
    required int count,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
        problem.problemNumber.trim().isEmpty ? 'N/A' : problem.problemNumber,
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2E43C6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _inlineStat({
    required IconData icon,
    required String tooltip,
    required int count,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProgress(ThemeData theme) {
    final safeTotal = totalIdeas <= 0 ? 1 : totalIdeas;
    final progress = (evaluatedCount / safeTotal).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress,
            color: const Color(0xFF7B1FA2),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Evaluated $evaluatedCount/$totalIdeas',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: 10,
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

}
