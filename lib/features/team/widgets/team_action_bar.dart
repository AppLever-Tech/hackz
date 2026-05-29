import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

class TeamActionBar extends StatelessWidget {
  const TeamActionBar({
    super.key,
    required this.canEdit,
    required this.canSubmitIdea,
    required this.onEdit,
    required this.onSubmitIdea,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final bool canEdit;
  final bool canSubmitIdea;
  final VoidCallback onEdit;
  final VoidCallback onSubmitIdea;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _action(AppIcons.edit, 'Edit Team', canEdit ? onEdit : null),
        _action(AppIcons.ideas, 'Submit Idea', canSubmitIdea ? onSubmitIdea : null),
        _action(AppIcons.preview, 'View Ideas', onViewIdeas),
        _action(AppIcons.statusInactive, 'Disable Team', onDisable, danger: true),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback? onTap, {bool danger = false}) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF4F46E5);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: onTap == null ? null : color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: onTap == null ? const Color(0xFFE2E8F0) : color.withOpacity(0.24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
