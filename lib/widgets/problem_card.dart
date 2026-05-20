import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/problem_model.dart';
import '../responsive/responsive_helper.dart';

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
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
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
      child: isMobile ? _buildMobileLayout(theme) : _buildDesktopLayout(theme),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    final visibleTags = problem.tags.take(3).toList(growable: false);
    final extraTagCount = problem.tags.length - visibleTags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _buildProblemNumberBadge(theme),
            const Spacer(),
            ..._buildActionButtons(iconOnly: false),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: _buildTitleRow(theme),
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
            Expanded(child: _buildDepartmentAttachmentRow(theme)),
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
        _buildTagsWrap(visibleTags, extraTagCount),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final visibleTags = problem.tags.take(3).toList(growable: false);
    final extraTagCount = problem.tags.length - visibleTags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildProblemNumberBadge(theme),
            const Spacer(),
            _buildMobileActionButtons(),
          ],
        ),
        const SizedBox(height: 10),
        _buildMobileTitleRow(theme),
        const SizedBox(height: 8),
        _buildDepartmentAttachmentRow(theme),
        const SizedBox(height: 10),
        _buildMobileTagsAndStatsRow(visibleTags, extraTagCount),
      ],
    );
  }

  Widget _buildMobileActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (canEdit)
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit == null ? null : () => onEdit!(problem),
            icon: const Icon(Icons.edit_outlined, size: 20),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (canEdit && canDelete) const SizedBox(width: 4),
        if (canDelete)
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete == null ? null : () => onDelete!(problem),
            icon: const Icon(Icons.delete_outline, size: 20),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileTitleRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(AppIcons.problems, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.loose,
          child: InkWell(
            onTap: onViewDetails == null ? null : () => onViewDetails!(problem),
            child: Text(
              problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: problem.isActive ? 'Active' : 'Inactive',
          child: Icon(
            problem.isActive ? AppIcons.statusActive : AppIcons.statusInactive,
            size: 12,
            color: problem.isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTagsAndStatsRow(List<String> visibleTags, int extraTagCount) {
    final tagWidgets = <Widget>[
      for (var i = 0; i < visibleTags.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(width: 6),
        _buildTagPill(visibleTags[i]),
      ],
      if (extraTagCount > 0) ...<Widget>[
        if (visibleTags.isNotEmpty) const SizedBox(width: 6),
        _buildMoreTagsPill(extraTagCount),
      ],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: tagWidgets,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _inlineStat(
          icon: AppIcons.ideas,
          tooltip: 'Total Ideas',
          count: totalIdeas,
          color: const Color(0xFF4A67FF),
        ),
        const SizedBox(width: 8),
        _inlineStat(
          icon: AppIcons.statusEvaluated,
          tooltip: 'Evaluated',
          count: evaluatedCount,
          color: const Color(0xFF7B1FA2),
        ),
        const SizedBox(width: 8),
        _inlineStat(
          icon: AppIcons.statusApproved,
          tooltip: 'Approved',
          count: approvedCount,
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons({required bool iconOnly}) {
    final buttons = <Widget>[];
    if (canEdit) {
      buttons.add(
        iconOnly
            ? IconButton(
                tooltip: 'Edit',
                onPressed: onEdit == null ? null : () => onEdit!(problem),
                icon: const Icon(Icons.edit_outlined, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            : OutlinedButton.icon(
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
      );
    }
    if (canEdit && canDelete) {
      buttons.add(SizedBox(width: iconOnly ? 4 : 8));
    }
    if (canDelete) {
      buttons.add(
        iconOnly
            ? IconButton(
                tooltip: 'Delete',
                onPressed: onDelete == null ? null : () => onDelete!(problem),
                icon: const Icon(Icons.delete_outline, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            : OutlinedButton.icon(
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
      );
    }
    return buttons;
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      children: <Widget>[
        Icon(AppIcons.problems, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            onTap: onViewDetails == null ? null : () => onViewDetails!(problem),
            child: Text(
              problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
    );
  }

  Widget _buildDepartmentAttachmentRow(ThemeData theme) {
    return Row(
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
        const SizedBox(width: 6),
        _inlineAttachmentCount(
          icon: AppIcons.attachments,
          tooltip: 'Attachments',
          count: attachmentCount,
          color: const Color(0xFF334155),
        ),
      ],
    );
  }

  Widget _buildTagsWrap(List<String> visibleTags, int extraTagCount) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        ...visibleTags.map(_buildTagPill),
        if (extraTagCount > 0) _buildMoreTagsPill(extraTagCount),
      ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onViewDetails == null ? null : () => onViewDetails!(problem),
      child: Container(
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
