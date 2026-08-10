import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import 'evaluation_template_workspace_loader.dart';

/// Compact header + about block for the evaluation template workspace.
class EvaluationTemplateSummarySection extends StatelessWidget {
  const EvaluationTemplateSummarySection({super.key, required this.vm});

  final EvaluationTemplateWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final String description = vm.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(AppIcons.scoring, size: 22, color: Color(0xFFB45309)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    vm.templateName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Evaluation Template',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      EntityCardPills.meta(
                        vm.statusLabel,
                        icon: vm.isActive ? AppIcons.verification : AppIcons.preview,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'About',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppSemanticColors.statusSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                vm.templateName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description.isEmpty
                    ? 'No description provided for this evaluation template.'
                    : description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: description.isEmpty
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
