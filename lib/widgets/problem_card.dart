import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/problem_model.dart';

class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    this.canEdit = false,
    this.canToggleActive = false,
    this.onEdit,
    this.onToggleActive,
    this.onViewAttachments,
    this.onViewDetails,
    this.initiallyExpanded = false,
  });

  final ProblemModel problem;
  final bool canEdit;
  final bool canToggleActive;
  final ValueChanged<ProblemModel>? onEdit;
  final ValueChanged<ProblemModel>? onToggleActive;
  final ValueChanged<ProblemModel>? onViewAttachments;
  final ValueChanged<ProblemModel>? onViewDetails;
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
                if (canEdit && canToggleActive) const SizedBox(width: 8),
                if (canToggleActive)
                  OutlinedButton.icon(
                    onPressed: onToggleActive == null ? null : () => onToggleActive!(problem),
                    icon: Icon(
                      problem.isActive ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                      size: 16,
                    ),
                    label: Text(problem.isActive ? 'Set Inactive' : 'Set Active'),
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
              children: <Widget>[
                Icon(AppIcons.problems, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(AppIcons.departments, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    problem.departmentDisplayName.trim().isEmpty ? '-' : problem.departmentDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(width: 8),
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
        problem.problemNumber.trim().isEmpty ? 'N/A' : problem.problemNumber,
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2E43C6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    final isActive = problem.isActive;
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

}
