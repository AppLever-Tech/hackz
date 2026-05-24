import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
import '../../utils/judge_evaluation_service.dart';

class EvaluationFeedbackSection extends StatelessWidget {
  const EvaluationFeedbackSection({super.key, required this.rows});

  final List<JudgeEvaluationFeedbackRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Feedback and remarks from your evaluations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = rows[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      r.ideaTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    r.overallScore.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formatDateTime(r.evaluatedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text(r.remarksExcerpt, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155))),
              if (r.hasStructuredCriteria) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: const <Widget>[
                    Icon(AppIcons.insights, size: 14, color: Color(0xFF6366F1)),
                    SizedBox(width: 4),
                    Text('Includes criteria scores', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
