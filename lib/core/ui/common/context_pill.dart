import 'package:flutter/material.dart';

import '../../theme/app_semantic_colors.dart';
import '../../workspace/context_launch_surface.dart';
import 'context_pill_metrics.dart';
import 'context_pill_theme.dart';

/// Interactive pill that opens a read-only contextual workspace (icon + label, no arrows).
class ContextPill extends StatelessWidget {
  const ContextPill({
    super.key,
    required this.label,
    required this.onTap,
    this.semantic = ContextPillSemantic.generic,
    this.icon,
    this.tooltip,
    this.compact = false,
    this.enabled = true,
    this.maxWidth,
    this.fitContent,
    this.expandWidth = false,
    this.height,
    this.minWidth,
    this.iconSize,
    this.allowHoverScale,
    this.maxLines = 1,
  });

  final String label;
  final VoidCallback onTap;
  final ContextPillSemantic semantic;
  /// Overrides [ContextPillTheme.iconFor] when set.
  final IconData? icon;
  /// Overrides [ContextPillMetrics.resolvedIconSize] when set.
  final double? iconSize;
  final String? tooltip;
  final bool compact;
  final bool enabled;
  final double? maxWidth;
  /// Sizes pill to icon + label. Defaults true for user/judge semantics.
  final bool? fitContent;
  /// When true, pill may grow to fill parent width (e.g. inside [Expanded]).
  final bool expandWidth;
  /// When set, pill uses a fixed height (e.g. uniform rows in idea cards).
  final double? height;
  /// Minimum width when sizing to content ([fitContent]).
  final double? minWidth;
  /// When false, hover avoids scale so clipped parents do not crop the pill.
  final bool? allowHoverScale;
  /// Label lines before clipping. Values other than `1` wrap instead of ellipsizing
  /// so a long name can stay fully visible inside a bounded parent.
  final int? maxLines;

  bool _fitContent(ContextPillSemantic semantic, bool? fitContent) =>
      fitContent ?? ContextPillTheme.defaultsToFitContent(semantic);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _buildPill(context, constraints);
      },
    );
  }

  Widget _buildPill(BuildContext context, BoxConstraints constraints) {
    final bool boundedWidth = constraints.maxWidth.isFinite;
    final String tooltipMessage = tooltip ?? ContextPillTheme.workspaceTooltipFor(semantic);
    final String display = label.trim().isEmpty ? '—' : label.trim();
    final bool interactive = enabled;
    final bool fitContent = _fitContent(semantic, this.fitContent);
    final bool useWorkspaceMetrics = ContextPillMetrics.isWorkspaceSemantic(semantic);
    final bool effectiveCompact = compact || useWorkspaceMetrics;
    final IconData resolvedIcon = icon ?? ContextPillTheme.iconFor(semantic);
    final double resolvedIconSize = iconSize ??
        ContextPillMetrics.resolvedIconSize(
          compact: effectiveCompact,
          semantic: semantic,
        );
    final double iconGap = ContextPillMetrics.resolvedIconGap(compact: effectiveCompact);
    final EdgeInsets pillPadding = ContextPillMetrics.resolvedPadding(
      context,
      compact: effectiveCompact,
    );
    double? layoutMaxWidth;
    if (expandWidth) {
      layoutMaxWidth = maxWidth ?? (boundedWidth ? constraints.maxWidth : null);
    } else if (maxWidth != null) {
      layoutMaxWidth = maxWidth;
    } else if (boundedWidth) {
      // Use the parent width so labels ellipsize only after filling available space.
      layoutMaxWidth = constraints.maxWidth;
    } else if (fitContent) {
      layoutMaxWidth = ContextPillTheme.defaultFitMaxWidth(
        compact: effectiveCompact,
        semantic: semantic,
      );
    }
    if (layoutMaxWidth != null && boundedWidth && layoutMaxWidth > constraints.maxWidth) {
      layoutMaxWidth = constraints.maxWidth;
    }
    final double resolvedHeight = ContextPillMetrics.resolvedHeight(
      context: context,
      compact: effectiveCompact,
      override: height,
    );
    final BorderRadius radius = ContextPillMetrics.resolvedBorderRadius(compact: effectiveCompact);
    final ContextPillPalette palette = ContextPillTheme.paletteFor(semantic);
    final Color labelColor = interactive ? palette.text : AppSemanticColors.metricText;
    final Color iconColor = ContextPillMetrics.iconColorFor(
      semantic: semantic,
      labelColor: labelColor,
    );
    final TextStyle labelStyle = ContextPillMetrics.labelStyle(
      labelColor,
      semantic: semantic,
    );
    final bool tightWidth = boundedWidth && constraints.maxWidth < 168;
    final bool resolvedAllowHoverScale =
        allowHoverScale ?? (!tightWidth && !expandWidth);
    final bool wrapLabel = maxLines != 1;

    final Widget labelText = Text(
      display,
      maxLines: wrapLabel ? maxLines : 1,
      overflow: wrapLabel ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: wrapLabel,
      textAlign: TextAlign.left,
      style: labelStyle,
    );

    final double innerBudget = layoutMaxWidth == null
        ? double.infinity
        : (layoutMaxWidth - pillPadding.horizontal).clamp(0.0, double.infinity);
    final double textBudget = (innerBudget - resolvedIconSize - iconGap).clamp(0.0, double.infinity);

    final Widget labelRow = Row(
      mainAxisSize: expandWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(resolvedIcon, size: resolvedIconSize, color: iconColor),
        SizedBox(width: iconGap),
        if (expandWidth)
          Expanded(child: labelText)
        else if (layoutMaxWidth != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: textBudget),
            child: labelText,
          )
        else
          labelText,
      ],
    );

    final double pillMaxWidth = expandWidth
        ? (layoutMaxWidth ?? (boundedWidth ? constraints.maxWidth : double.infinity))
        : (boundedWidth ? constraints.maxWidth : (layoutMaxWidth ?? double.infinity));

    return ContextLaunchSurface(
      semantic: semantic,
      onTap: onTap,
      enabled: interactive,
      tooltip: tooltip,
      semanticsLabel: '$display. $tooltipMessage',
      borderRadius: radius,
      allowHoverScale: resolvedAllowHoverScale,
      padding: pillPadding,
      constraints: BoxConstraints(
        minHeight: resolvedHeight,
        maxHeight: wrapLabel ? double.infinity : resolvedHeight,
        minWidth: minWidth ?? 0,
        maxWidth: pillMaxWidth,
      ),
      child: wrapLabel
          ? labelRow
          : SizedBox(
              height: resolvedHeight,
              width: expandWidth ? double.infinity : null,
              child: expandWidth
                  ? Align(alignment: Alignment.centerLeft, child: labelRow)
                  : labelRow,
            ),
    );
  }
}
