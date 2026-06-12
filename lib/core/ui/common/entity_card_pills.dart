import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import 'context_pill.dart';
import 'context_pill_metrics.dart';
import 'context_pill_theme.dart';
import 'form_value_row.dart';

/// Workspace and meta chips shared by idea/problem dashboard cards.
abstract final class EntityCardPills {
  static Widget workspace(
    String label,
    ContextPillSemantic semantic,
    VoidCallback onTap, {
    bool fullWidth = false,
    IconData? icon,
  }) {
    final Widget pill = ContextPill(
      label: label,
      semantic: semantic,
      icon: icon ?? ContextPillTheme.iconFor(semantic),
      onTap: onTap,
      compact: true,
      height: ContextPillMetrics.workspaceHeight,
      fitContent: !fullWidth,
      expandWidth: fullWidth,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: ContextPillMetrics.workspaceHeight, child: pill);
    }
    return pill;
  }

  static Widget meta(String label, {IconData? icon}) {
    return SizedBox(
      height: ContextPillMetrics.workspaceHeight,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppSemanticColors.statusSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppSemanticColors.statusBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: ContextPillMetrics.iconSize, color: AppSemanticColors.statusText),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppSemanticColors.statusText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget plainValue(String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: EntityCardStyles.plainValue,
      ),
    );
  }
}
