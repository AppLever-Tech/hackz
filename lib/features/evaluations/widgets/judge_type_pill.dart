import 'package:flutter/material.dart';

import '../../user/models/enums/judge_type.dart';

/// Compact pill for [JudgeProfile.judgeType].
class JudgeTypePill extends StatelessWidget {
  const JudgeTypePill({
    super.key,
    required this.judgeType,
    this.compact = true,
  });

  final JudgeType? judgeType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final JudgeType? type = judgeType;
    if (type == null) return const SizedBox.shrink();

    final Color color = colorFor(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(iconFor(type), size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Color colorFor(JudgeType type) {
    return switch (type) {
      JudgeType.internal => const Color(0xFF4338CA),
      JudgeType.external => const Color(0xFF0891B2),
      JudgeType.industry => const Color(0xFFEA580C),
      JudgeType.academic => const Color(0xFF059669),
    };
  }

  static IconData iconFor(JudgeType type) {
    return switch (type) {
      JudgeType.internal => Icons.corporate_fare_outlined,
      JudgeType.external => Icons.public_outlined,
      JudgeType.industry => Icons.factory_outlined,
      JudgeType.academic => Icons.school_outlined,
    };
  }
}
