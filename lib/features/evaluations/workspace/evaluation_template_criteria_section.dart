import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../models/evaluation_criterion.dart';
import 'evaluation_template_workspace_loader.dart';

/// Read-only criteria list with optional org/department grouping.
class EvaluationTemplateCriteriaSection extends StatelessWidget {
  const EvaluationTemplateCriteriaSection({super.key, required this.vm});

  final EvaluationTemplateWorkspaceViewModel vm;

  static const Color _weightAccent = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              'Evaluation Criteria (${vm.criteriaCount})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              'Scoring Scale ${vm.template.scoringScale}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vm.criteriaCount == 0)
          _emptyState()
        else if (vm.hasDepartmentSections) ...<Widget>[
          _groupLabel('Organization'),
          const SizedBox(height: 6),
          for (final EvaluationCriterion c in vm.orgCriteria) _CriterionRow(vm: vm, criterion: c),
          if (vm.departmentCriteria.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _groupLabel('Department extensions'),
            const SizedBox(height: 6),
            for (final EvaluationCriterion c in vm.departmentCriteria)
              _CriterionRow(vm: vm, criterion: c),
          ],
        ] else
          for (final EvaluationCriterion c in vm.template.orderedCriteria)
            _CriterionRow(vm: vm, criterion: c),
      ],
    );
  }

  static Widget _groupLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    );
  }

  static Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppSemanticColors.statusSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: <Widget>[
          Icon(AppIcons.scoring, size: 18, color: Color(0xFF94A3B8)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No criteria configured on this template yet.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.vm, required this.criterion});

  final EvaluationTemplateWorkspaceViewModel vm;
  final EvaluationCriterion criterion;

  @override
  Widget build(BuildContext context) {
    final String weightLabel =
        vm.weightLabelsByCriterionId[criterion.criterionId] ?? '—';
    final double fraction = vm.totalWeight <= 0
        ? 0
        : (criterion.weight / vm.totalWeight).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: ColoredBox(
                  color: EvaluationTemplateCriteriaSection._weightAccent.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        criterion.title.trim().isEmpty ? 'Criterion' : criterion.title.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight: $weightLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${criterion.minScore}–${criterion.maxScore}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
