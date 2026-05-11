import 'package:flutter/material.dart';

import '../../utils/department_dashboard_service.dart';

class ProblemAnalyticsWidget extends StatelessWidget {
  const ProblemAnalyticsWidget({
    super.key,
    required this.activeProblems,
    required this.problemsByTheme,
    required this.ideaInflowByProblem,
  });

  final int activeProblems;
  final List<DepartmentDistributionSegment> problemsByTheme;
  final List<DepartmentProblemPoint> ideaInflowByProblem;

  @override
  Widget build(BuildContext context) {
    final int maxIdeas = ideaInflowByProblem.fold<int>(1, (max, point) => point.count > max ? point.count : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Problem Management Analytics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ),
            _MetricPill(label: 'Active', value: '$activeProblems'),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Themes, active problem volume and idea inflow health', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Problems by theme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                if (problemsByTheme.isEmpty)
                  const Text('No problem themes available yet.', style: TextStyle(color: Color(0xFF64748B)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: problemsByTheme
                        .map(
                          (segment) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: segment.color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('${segment.label} · ${segment.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 16),
                const Text('Idea inflow per problem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                const SizedBox(height: 8),
                if (ideaInflowByProblem.isEmpty)
                  const Text('No idea inflow data yet.', style: TextStyle(color: Color(0xFF64748B)))
                else
                  ...ideaInflowByProblem.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  point.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                                ),
                              ),
                              Text('${point.count}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 7,
                              value: point.count / maxIdeas,
                              color: const Color(0xFF6A38FF),
                              backgroundColor: const Color(0xFFE8ECF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF2EDFF), borderRadius: BorderRadius.circular(999)),
      child: Text('$label $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
    );
  }
}
