import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../responsive/responsive_helper.dart';
import 'context_pill_metrics.dart';
import 'context_pill_theme.dart';

/// Interactive pill that opens a read-only contextual workspace (icon + label, no arrows).
class ContextPill extends StatefulWidget {
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

  @override
  State<ContextPill> createState() => _ContextPillState();
}

class _ContextPillState extends State<ContextPill> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _pressing = false;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  void _setHover(bool value) {
    if (!widget.enabled || ResponsiveHelper.isMobile(context)) return;
    if (_hovering == value) return;
    setState(() => _hovering = value);
    if (value) {
      _shimmer.repeat();
    } else {
      _shimmer.stop();
    }
  }

  bool get _fitContent =>
      widget.fitContent ?? ContextPillTheme.defaultsToFitContent(widget.semantic);

  double? get _resolvedMaxWidth {
    if (widget.maxWidth != null) return widget.maxWidth;
    if (widget.expandWidth) return null;
    if (_fitContent) {
      return ContextPillTheme.defaultFitMaxWidth(compact: widget.compact, semantic: widget.semantic);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ContextPillPalette palette = ContextPillTheme.paletteFor(widget.semantic);
    final String tooltipMessage = widget.tooltip ?? ContextPillTheme.workspaceTooltipFor(widget.semantic);
    final String display = widget.label.trim().isEmpty ? '—' : widget.label.trim();
    final bool interactive = widget.enabled;
    final bool showHoverFx = interactive && _hovering && !ResponsiveHelper.isMobile(context);
    final double scale = !interactive ? 1 : (_pressing ? 0.98 : (showHoverFx ? 1.02 : 1));
    final IconData icon = widget.icon ?? ContextPillTheme.iconFor(widget.semantic);
    final double iconSize =
        widget.iconSize ?? ContextPillMetrics.resolvedIconSize(compact: widget.compact);
    final double iconGap = ContextPillMetrics.resolvedIconGap(compact: widget.compact);
    final double? maxWidth = _resolvedMaxWidth;
    final double resolvedHeight =
        ContextPillMetrics.resolvedHeight(context: context, compact: widget.compact, override: widget.height);

    final BorderRadius radius = ContextPillMetrics.resolvedBorderRadius(compact: widget.compact);
    final Color borderColor = !interactive
        ? AppSemanticColors.metricBorder
        : (showHoverFx ? palette.borderHover : palette.border);
    final Color surfaceColor = !interactive
        ? AppSemanticColors.metricSurface
        : (showHoverFx ? palette.surfaceHover : palette.surface);

    final Color labelColor = interactive ? palette.text : AppSemanticColors.metricText;
    final TextStyle labelStyle = ContextPillMetrics.labelStyle(labelColor);

    final Widget labelText = Text(
      display,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      style: labelStyle,
    );

    final bool constrainLabel = widget.expandWidth || maxWidth != null;

    Widget labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: iconSize, color: labelColor),
        SizedBox(width: iconGap),
        if (constrainLabel)
          Flexible(
            fit: widget.expandWidth ? FlexFit.tight : FlexFit.loose,
            child: labelText,
          )
        else
          labelText,
      ],
    );

    if (maxWidth != null) {
      labelRow = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: labelRow,
      );
    }

    Widget pillBody = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minHeight: resolvedHeight,
          maxHeight: resolvedHeight,
          minWidth: widget.minWidth ?? 0,
          maxWidth: widget.expandWidth ? (widget.maxWidth ?? double.infinity) : maxWidth ?? double.infinity,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: showHoverFx ? ContextPillMetrics.borderWidthHover : ContextPillMetrics.borderWidth,
          ),
          boxShadow: showHoverFx
              ? <BoxShadow>[
                  BoxShadow(color: palette.glow, blurRadius: 14, offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: widget.expandWidth ? StackFit.expand : StackFit.loose,
            children: <Widget>[
              if (showHoverFx)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (BuildContext context, Widget? child) {
                      final double t = _shimmer.value;
                      return IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.2 + t * 2.4, 0),
                              end: Alignment(-0.6 + t * 2.4, 0),
                              colors: <Color>[
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (widget.expandWidth)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: ContextPillMetrics.resolvedPadding(context, compact: widget.compact),
                      child: labelRow,
                    ),
                  ),
                )
              else
                Padding(
                  padding: ContextPillMetrics.resolvedPadding(context, compact: widget.compact),
                  child: SizedBox(
                    height: resolvedHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: labelRow,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      child: Semantics(
        button: interactive,
        enabled: interactive,
        label: '$display. $tooltipMessage',
        child: MouseRegion(
          onEnter: (_) => _setHover(true),
          onExit: (_) => _setHover(false),
          cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: interactive ? (_) => setState(() => _pressing = true) : null,
            onTapUp: interactive ? (_) => setState(() => _pressing = false) : null,
            onTapCancel: interactive ? () => setState(() => _pressing = false) : null,
            onTap: interactive ? widget.onTap : null,
            child: pillBody,
          ),
        ),
      ),
    );
  }
}
