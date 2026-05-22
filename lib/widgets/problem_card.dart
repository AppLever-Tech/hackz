import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/problem_model.dart';
import '../screens/common/dashboard_components.dart';
import 'common/entity_card_pills.dart';
import 'common/context_pill_theme.dart';
import 'common/form_value_row.dart';

class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.problem,
    this.onOpenProblem,
    this.onSubmitIdea,
    this.showSubmitIdea = false,
    this.canEdit = false,
    this.canDelete = false,
    this.onEdit,
    this.onDelete,
  });

  final ProblemModel problem;
  final VoidCallback? onOpenProblem;
  final VoidCallback? onSubmitIdea;
  final bool showSubmitIdea;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<ProblemModel>? onEdit;
  final ValueChanged<ProblemModel>? onDelete;

  @override
  Widget build(BuildContext context) {
    final String title = problem.title.trim().isEmpty ? 'Untitled Problem' : problem.title.trim();
    final String department =
        problem.departmentDisplayName.trim().isEmpty ? '—' : problem.departmentDisplayName.trim();
    final String category = problem.category.trim().isEmpty ? '—' : problem.category.trim();
    final String theme = problem.theme.trim().isEmpty ? '—' : problem.theme.trim();
    final List<String> tags = problem.tags.map((String t) => t.trim()).where((String t) => t.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTitle(title),
                    const SizedBox(height: 8),
                    _buildMetaPillsRow(
                      department: department,
                      category: category,
                      theme: theme,
                      tags: tags,
                    ),
                  ],
                ),
              ),
              if (canEdit || canDelete) ...<Widget>[
                if (canEdit)
                  IconButton(
                    tooltip: 'Edit problem',
                    onPressed: onEdit == null ? null : () => onEdit!(problem),
                    icon: const Icon(AppIcons.edit, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Delete problem',
                    onPressed: onDelete == null ? null : () => onDelete!(problem),
                    icon: const Icon(AppIcons.remove, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ],
          ),
          if (showSubmitIdea && onSubmitIdea != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onSubmitIdea,
                icon: const Icon(AppIcons.ideas, size: 18),
                label: const Text('Submit Idea'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    if (onOpenProblem != null) {
      return EntityCardPills.workspace(
        title,
        ContextPillSemantic.problem,
        onOpenProblem!,
        fullWidth: true,
        icon: AppIcons.problems,
      );
    }
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: EntityCardStyles.plainValue,
    );
  }

  Widget _buildMetaPillsRow({
    required String department,
    required String category,
    required String theme,
    required List<String> tags,
  }) {
    final List<Widget> pills = <Widget>[
      EntityCardPills.meta(department, icon: AppIcons.departments),
      EntityCardPills.meta(category, icon: AppIcons.orgType),
      EntityCardPills.meta(theme, icon: AppIcons.insights),
      ...tags.map((String tag) => EntityCardPills.meta(tag)),
      if (tags.isEmpty) EntityCardPills.meta('No tags'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: _spacedMetaPills(pills),
      ),
    );
  }

  static List<Widget> _spacedMetaPills(List<Widget> pills) {
    if (pills.isEmpty) return pills;
    final List<Widget> spaced = <Widget>[pills.first];
    for (var i = 1; i < pills.length; i++) {
      spaced.add(const SizedBox(width: 6));
      spaced.add(pills[i]);
    }
    return spaced;
  }
}
