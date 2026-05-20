import 'package:flutter/material.dart';

import 'context_pill.dart';
import 'context_pill_theme.dart';

/// Field label + contextual workspace pill (e.g. Mentor → [ Vinay ]).
class ContextPillGroup extends StatelessWidget {
  const ContextPillGroup({
    super.key,
    this.fieldLabel,
    required this.pillLabel,
    required this.onOpenWorkspace,
    this.semantic,
    this.workspaceEntityLabel,
    this.compact = false,
    this.leadingIcon,
    this.maxPillWidth,
  });

  final String? fieldLabel;
  final String pillLabel;
  final VoidCallback onOpenWorkspace;
  final ContextPillSemantic? semantic;
  final String? workspaceEntityLabel;
  final bool compact;
  final IconData? leadingIcon;
  final double? maxPillWidth;

  @override
  Widget build(BuildContext context) {
    final ContextPillSemantic resolved =
        semantic ?? ContextPillTheme.semanticFromEntityLabel(workspaceEntityLabel ?? fieldLabel);

    final TextStyle? fieldStyle = fieldLabel == null
        ? null
        : TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.2,
          );

    if (fieldLabel == null) {
      return ContextPill(
        label: pillLabel,
        onTap: onOpenWorkspace,
        semantic: resolved,
        compact: compact,
        maxWidth: maxPillWidth,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: compact ? 14 : 16, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
          ],
          if (fieldStyle != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(fieldLabel!, style: fieldStyle),
            ),
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ContextPill(
                label: pillLabel,
                onTap: onOpenWorkspace,
                semantic: resolved,
                compact: compact,
                maxWidth: maxPillWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
