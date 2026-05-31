import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../shared/workspace/context_launch_surface.dart';
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

  bool _fitContent(ContextPillSemantic semantic, bool? fitContent) =>
      fitContent ?? ContextPillTheme.defaultsToFitContent(semantic);

  double? _resolvedMaxWidth({
    required bool expandWidth,
    required bool fitContent,
    required bool effectiveCompact,
    required ContextPillSemantic semantic,
    required double? maxWidth,
  }) {
    if (maxWidth != null) return maxWidth;
    if (expandWidth) return null;
    if (fitContent) {
      return ContextPillTheme.defaultFitMaxWidth(
        compact: effectiveCompact,
        semantic: semantic,
      );
    }
    return null;
  }

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
    final double? themeMaxWidth = _resolvedMaxWidth(
      expandWidth: expandWidth,
      fitContent: fitContent,
      effectiveCompact: effectiveCompact,
      semantic: semantic,
      maxWidth: maxWidth,
    );
    final double? layoutMaxWidth = expandWidth
        ? (maxWidth ?? (boundedWidth ? constraints.maxWidth : null))
        : (themeMaxWidth ?? (boundedWidth && !fitContent ? constraints.maxWidth : null));
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

    final Widget labelText = Text(
      display,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      style: labelStyle,
    );

    final bool constrainLabel = expandWidth || layoutMaxWidth != null;

    Widget labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(resolvedIcon, size: resolvedIconSize, color: iconColor),
        SizedBox(width: iconGap),
        if (constrainLabel)
          Flexible(
            fit: expandWidth ? FlexFit.tight : FlexFit.loose,
            child: labelText,
          )
        else
          labelText,
      ],
    );

    if (layoutMaxWidth != null && !expandWidth) {
      labelRow = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layoutMaxWidth),
        child: labelRow,
      );
    }

    final double pillMaxWidth = expandWidth
        ? (layoutMaxWidth ?? double.infinity)
        : (layoutMaxWidth ?? (boundedWidth ? constraints.maxWidth : double.infinity));

    final Widget content = expandWidth
        ? Align(
            alignment: Alignment.centerLeft,
            child: labelRow,
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: labelRow,
          );

    return ContextLaunchSurface(
      semantic: semantic,
      onTap: onTap,
      enabled: interactive,
      tooltip: tooltip,
      semanticsLabel: '$display. $tooltipMessage',
      borderRadius: radius,
      padding: ContextPillMetrics.resolvedPadding(context, compact: effectiveCompact),
      constraints: BoxConstraints(
        minHeight: resolvedHeight,
        maxHeight: resolvedHeight,
        minWidth: minWidth ?? 0,
        maxWidth: pillMaxWidth,
      ),
      child: SizedBox(
        height: resolvedHeight,
        width: expandWidth ? double.infinity : null,
        child: content,
      ),
    );
  }
}
