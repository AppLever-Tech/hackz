import 'package:flutter/material.dart';

import '../../core/ui/common/context_pill.dart';
import '../../core/ui/common/context_pill_group.dart';
import '../../core/ui/common/context_pill_theme.dart';

/// Informational row, or field label + [ContextPill] for workspace navigation.
class EntityReferenceRow extends StatelessWidget {
  const EntityReferenceRow({
    super.key,
    this.leadingIcon,
    this.label,
    required this.value,
    this.maxLines = 1,
    this.dense = false,
    this.onOpenWorkspace,
    this.workspaceEntityLabel,
    this.semantic,
  });

  final IconData? leadingIcon;
  final String? label;
  final String value;
  final int maxLines;
  final bool dense;
  final VoidCallback? onOpenWorkspace;
  final String? workspaceEntityLabel;
  final ContextPillSemantic? semantic;

  @override
  Widget build(BuildContext context) {
    if (onOpenWorkspace != null) {
      return ContextPillGroup(
        fieldLabel: label,
        pillLabel: value,
        onOpenWorkspace: onOpenWorkspace!,
        semantic: semantic,
        workspaceEntityLabel: workspaceEntityLabel,
        compact: dense,
        leadingIcon: leadingIcon,
      );
    }

    final TextStyle valueStyle = TextStyle(
      fontSize: dense ? 12 : 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF334155),
      height: 1.25,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: dense ? 14 : 16, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label == null ? value : '$label $value',
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
