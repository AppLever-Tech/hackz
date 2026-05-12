import 'package:flutter/material.dart';

import '../../utils/coordinator_dashboard_service.dart';
import 'coordinator_panel_card.dart';

class SubmissionWorkflowFunnel extends StatelessWidget {
  const SubmissionWorkflowFunnel({super.key, required this.steps});

  final List<SubmissionWorkflowStep> steps;

  @override
  Widget build(BuildContext context) {
    final maxCount = steps.fold<int>(0, (max, step) => step.count > max ? step.count : max);
    return CoordinatorPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Submission Workflow Funnel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Processing visibility from idea creation to official submission', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...steps.map((step) {
            final widthFactor = maxCount == 0 ? 0.08 : (step.count / maxCount).clamp(0.08, 1.0).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 138,
                    child: Text(step.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w800)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: <Widget>[
                          Container(height: 30, color: const Color(0xFFF1F5F9)),
                          FractionallySizedBox(
                            widthFactor: widthFactor,
                            child: Container(
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: <Color>[step.color.withValues(alpha: 0.72), step.color]),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text('${step.count}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

