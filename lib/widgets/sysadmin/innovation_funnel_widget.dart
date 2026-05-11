import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';

class InnovationFunnelWidget extends StatelessWidget {
  const InnovationFunnelWidget({
    super.key,
    required this.steps,
  });

  final List<InnovationFunnelStep> steps;

  @override
  Widget build(BuildContext context) {
    final int maxCount = steps.fold<int>(1, (int max, InnovationFunnelStep s) => s.count > max ? s.count : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Innovation Funnel',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Problems → teams → ideas → evaluation → approval flow',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ...steps.map((InnovationFunnelStep step) {
          final double ratio = maxCount == 0 ? 0 : step.count / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 82,
                  child: Text(
                    step.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.08, 1),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: <Color>[step.color.withOpacity(0.72), step.color]),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '${step.count}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
