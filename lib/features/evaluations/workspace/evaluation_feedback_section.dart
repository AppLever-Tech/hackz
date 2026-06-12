import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'evaluation_workspace_loader.dart';

class EvaluationFeedbackSection extends StatelessWidget {
  const EvaluationFeedbackSection({super.key, required this.vm});

  final EvaluationWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Feedback',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        _feedbackCard(
          title: 'Strengths',
          icon: AppIcons.workflowApproved,
          color: const Color(0xFF047857),
          items: vm.strengths,
          emptyText: 'No strengths highlighted in evaluation feedback.',
        ),
        const SizedBox(height: 8),
        _feedbackCard(
          title: 'Improvements',
          icon: AppIcons.info,
          color: const Color(0xFFEA580C),
          items: vm.improvements,
          emptyText: 'No improvement notes recorded.',
        ),
        const SizedBox(height: 8),
        _recommendationCard(),
      ],
    );
  }

  Widget _recommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(AppIcons.insights, size: 16, color: Color(0xFF6D28D9)),
              SizedBox(width: 8),
              Text(
                'Recommendation summary',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vm.recommendationSummary,
            style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _feedbackCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4))
          else
            ...items.map(
              (String line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
