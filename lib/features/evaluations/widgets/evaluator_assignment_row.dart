import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import '../../user/widgets/user_avatar.dart';
import '../services/evaluator_catalog_service.dart';

/// Compact evaluator row: photo, name, role badge.
class EvaluatorAssignmentRow extends StatelessWidget {
  const EvaluatorAssignmentRow({
    super.key,
    required this.evaluator,
    required this.selected,
    required this.workloadLabel,
    required this.onToggle,
    this.conflictLabel,
    this.enabled = true,
  });

  final UserModel evaluator;
  final bool selected;
  final String workloadLabel;
  final VoidCallback onToggle;
  final String? conflictLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String badge = EvaluatorCatalogService.roleBadgeLabel(evaluator);
    final bool rowEnabled = enabled && conflictLabel == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: selected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: rowEnabled ? (_) => onToggle() : null,
            ),
          ),
          const SizedBox(width: 8),
          UserAvatar(user: evaluator, radius: 14, fontSize: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  evaluator.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                _RoleBadge(label: badge),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _MetaPill(
            text: workloadLabel,
            background: const Color(0xFFEFF6FF),
            border: const Color(0xFFBFDBFE),
            foreground: const Color(0xFF1D4ED8),
          ),
          if (conflictLabel != null) ...<Widget>[
            const SizedBox(width: 6),
            _MetaPill(
              text: conflictLabel!,
              background: const Color(0xFFFFF1F2),
              border: const Color(0xFFFDA4AF),
              foreground: const Color(0xFFBE123C),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
