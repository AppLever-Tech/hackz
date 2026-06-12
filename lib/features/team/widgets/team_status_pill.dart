import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/enums/team_status.dart';

class TeamStatusPill extends StatelessWidget {
  const TeamStatusPill({
    super.key,
    required this.status,
    this.lockedAfterSubmission = false,
  });

  final TeamStatus status;
  final bool lockedAfterSubmission;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Color get _color {
    if (status == TeamStatus.inactive) return const Color(0xFF64748B);
    if (status == TeamStatus.locked || lockedAfterSubmission) return const Color(0xFF7C3AED);
    return const Color(0xFF16A34A);
  }

  IconData get _icon {
    if (status == TeamStatus.inactive) return AppIcons.statusInactive;
    if (status == TeamStatus.locked || lockedAfterSubmission) return AppIcons.verification;
    return AppIcons.statusActive;
  }

  String get _label {
    if (status == TeamStatus.inactive) return 'Inactive';
    if (status == TeamStatus.locked || lockedAfterSubmission) return 'Locked after submission';
    return 'Active · Editable';
  }
}
