import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/workflow_status.dart';

/// Compact semantic status badge shared across faculty + dept admin surfaces.
class WorkflowStatusPill extends StatelessWidget {
  const WorkflowStatusPill({
    super.key,
    required this.status,
    this.dense = false,
  });

  final WorkflowStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final _StatusVisuals v = _visualsFor(status);
    final double iconSize = dense ? 12 : 13;
    final double fontSize = dense ? 10.5 : 11.5;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: v.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: v.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(v.icon, size: iconSize, color: v.foreground),
          SizedBox(width: dense ? 4 : 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: v.foreground,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusVisuals _visualsFor(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.draft:
        return const _StatusVisuals(
          icon: Icons.edit_note_rounded,
          foreground: Color(0xFF475569),
          background: Color(0xFFF1F5F9),
          border: Color(0xFFE2E8F0),
        );
      case WorkflowStatus.pendingApproval:
        return const _StatusVisuals(
          icon: AppIcons.statusUnderReview,
          foreground: Color(0xFFB45309),
          background: Color(0xFFFFF7E6),
          border: Color(0xFFFDE4B0),
        );
      case WorkflowStatus.approved:
        return const _StatusVisuals(
          icon: AppIcons.statusApproved,
          foreground: Color(0xFF047857),
          background: Color(0xFFE9FAF0),
          border: Color(0xFFB9EBC8),
        );
      case WorkflowStatus.rejected:
        return const _StatusVisuals(
          icon: AppIcons.statusRejected,
          foreground: Color(0xFFB91C1C),
          background: Color(0xFFFEECEC),
          border: Color(0xFFF8C4C4),
        );
    }
  }
}

class _StatusVisuals {
  const _StatusVisuals({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}
