import 'package:flutter/material.dart';

import '../models/ideathon_status.dart';
import '../services/ideathon_status_helpers.dart';

class IdeathonStatusPill extends StatelessWidget {
  const IdeathonStatusPill({
    super.key,
    required this.status,
    this.compact = true,
  });

  final IdeathonStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = IdeathonStatusHelpers.color(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: IdeathonStatusHelpers.background(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(IdeathonStatusHelpers.icon(status), size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            IdeathonStatusHelpers.label(status),
            style: TextStyle(fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
