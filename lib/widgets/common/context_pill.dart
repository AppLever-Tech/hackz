import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../responsive/responsive_helper.dart';
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
  });

  final String label;
  final VoidCallback onTap;
  final ContextPillSemantic semantic;
  /// Overrides [ContextPillTheme.iconFor] when set.
  final IconData? icon;
  final String? tooltip;
  final bool compact;
  final bool enabled;
  final double? maxWidth;
  /// Sizes pill to icon + label. Defaults true for user/judge semantics.
  final bool? fitContent;
  /// When true, pill may grow to fill parent width (e.g. inside [Expanded]).
  final bool expandWidth;

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
    final double iconSize = ContextPillTheme.iconSizeFor(compact: widget.compact);
    final double? maxWidth = _resolvedMaxWidth;

    final BorderRadius radius = ContextPillTheme.borderRadiusFor(compact: widget.compact);
    final Color borderColor = !interactive
        ? AppSemanticColors.metricBorder
        : (showHoverFx ? palette.borderHover : palette.border);
    final Color surfaceColor = !interactive
        ? AppSemanticColors.metricSurface
        : (showHoverFx ? palette.surfaceHover : palette.surface);

    final TextStyle labelStyle = TextStyle(
      fontSize: widget.compact ? 11 : 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      color: interactive ? palette.text : AppSemanticColors.metricText,
      height: 1.15,
    );

    Widget labelRow = Row(
      mainAxisSize: widget.expandWidth ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: iconSize, color: interactive ? palette.text : AppSemanticColors.metricText),
        SizedBox(width: widget.compact ? 5 : 6),
        Flexible(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
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
          minHeight: ContextPillTheme.minHeightFor(context, compact: widget.compact),
          maxWidth: widget.expandWidth ? (widget.maxWidth ?? double.infinity) : maxWidth ?? double.infinity,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: showHoverFx ? 1.4 : 1),
          boxShadow: showHoverFx
              ? <BoxShadow>[
                  BoxShadow(color: palette.glow, blurRadius: 14, offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: <Widget>[
              if (showHoverFx)
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (BuildContext context, Widget? child) {
                    final double t = _shimmer.value;
                    return Positioned.fill(
                      child: IgnorePointer(
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
                      ),
                    );
                  },
                ),
              Padding(
                padding: ContextPillTheme.paddingFor(context, compact: widget.compact),
                child: labelRow,
              ),
            ],
          ),
        ),
      ),
    );

    if (_fitContent && !widget.expandWidth) {
      pillBody = IntrinsicWidth(child: pillBody);
    }

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
