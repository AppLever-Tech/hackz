import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';

class OrganizationAnalyticsChart extends StatelessWidget {
  const OrganizationAnalyticsChart({
    super.key,
    required this.points,
  });

  final List<OrganizationActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    final int maxActivity = points.fold<int>(1, (int max, OrganizationActivityPoint p) => p.activity > max ? p.activity : max);
    final visible = points.take(8).toList(growable: false);
    final int activeDepartments = points.fold<int>(0, (int total, OrganizationActivityPoint p) => total + p.activeDepartments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Organization Participation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
            _MiniStat(label: 'Active depts', value: '$activeDepartments'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Activity distribution by organization, sorted alphabetically',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const SizedBox(height: 180, child: Center(child: Text('No organization activity yet')))
        else
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: visible.map((OrganizationActivityPoint p) {
                final double ratio = p.activity / maxActivity;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${p.activity}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.08, 1),
                              widthFactor: 0.92,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: <Color>[Color(0xFF6A38FF), Color(0xFF93C5FD)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: '${p.name}\n${p.activeDepartments} active departments',
                          child: Text(
                            _shortName(p.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
      ],
    );
  }

  String _shortName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 9) return trimmed;
    return '${trimmed.substring(0, 8)}…';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5B21B6)),
      ),
    );
  }
}
