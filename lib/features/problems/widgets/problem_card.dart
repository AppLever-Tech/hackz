import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../widgets/common/form_value_row.dart';
import '../models/problem_model.dart';
import '../validators/problem_submission_validators.dart';
import 'problem_submission_status_pill.dart';

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
    this.gate,
  });

  final ProblemModel problem;
  final VoidCallback? onOpenProblem;
  final VoidCallback? onSubmitIdea;
  final bool showSubmitIdea;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<ProblemModel>? onEdit;
  final ValueChanged<ProblemModel>? onDelete;

  /// Submission-control snapshot computed by the host list screen. When
  /// non-null, drives the in-card status indicator and Submit button states;
  /// when null, the card renders without these affordances (backward
  /// compatible with consumers that haven't been migrated).
  final IdeaSubmissionGate? gate;

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
          if (showSubmitIdea) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSubmitButton(),
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
    final IdeaSubmissionGate? g = gate;
    final List<Widget> pills = <Widget>[
      EntityCardPills.meta(department, icon: AppIcons.departments),
      EntityCardPills.meta(category, icon: AppIcons.orgType),
      EntityCardPills.meta(theme, icon: AppIcons.insights),
      // Submission status pill is placed up-front so it stays visible when the
      // tag list pushes the meta row into horizontal scroll.
      if (g != null) ProblemSubmissionStatusPill(gate: g),
      ...tags.map((String tag) => EntityCardPills.meta(tag)),
      if (tags.isEmpty && g == null) EntityCardPills.meta('No tags'),
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

  /// Renders the Submit button in one of three states keyed off [gate]:
  ///   * open / no-gate            → enabled "Submit Idea" (existing behaviour)
  ///   * limitReached              → disabled "Idea Limit Reached"
  ///   * deadlinePassed / inactive → disabled "Submission Closed"
  ///
  /// When [onSubmitIdea] is null the button is rendered disabled regardless
  /// of gate state (mirrors the previous behaviour for callers that don't
  /// supply a handler).
  Widget _buildSubmitButton() {
    final IdeaSubmissionGate? g = gate;
    final bool defaultDisabled = onSubmitIdea == null;
    String label = 'Submit Idea';
    IconData icon = AppIcons.ideas;
    bool disabled = defaultDisabled;

    if (g != null) {
      switch (g.state) {
        case IdeaSubmissionGateState.open:
          // Keep defaults.
          break;
        case IdeaSubmissionGateState.limitReached:
          label = 'Idea Limit Reached';
          icon = Icons.block_rounded;
          disabled = true;
          break;
        case IdeaSubmissionGateState.deadlinePassed:
        case IdeaSubmissionGateState.inactive:
          label = 'Submission Closed';
          icon = Icons.lock_outline_rounded;
          disabled = true;
          break;
      }
    }

    return FilledButton.icon(
      onPressed: disabled ? null : onSubmitIdea,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
