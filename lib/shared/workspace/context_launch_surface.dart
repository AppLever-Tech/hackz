import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../widgets/common/context_pill_metrics.dart';
import '../../widgets/common/context_pill_theme.dart';

/// Shared hover, press, shimmer, and border styling for workspace launch controls.
///
/// Used by [ContextPill], [UserWorkspaceAvatar], and other workspace entry points.
class ContextLaunchSurface extends StatefulWidget {
  const ContextLaunchSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.semantic = ContextPillSemantic.generic,
    this.tooltip,
    this.enabled = true,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.semanticsLabel,
    this.constraints,
    this.allowHoverScale = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final ContextPillSemantic semantic;
  final String? tooltip;
  final bool enabled;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;
  final BoxConstraints? constraints;
  /// When false, hover uses color/border/shimmer only (avoids clip in tight cells).
  final bool allowHoverScale;

  @override
  State<ContextLaunchSurface> createState() => _ContextLaunchSurfaceState();
}

class _ContextLaunchSurfaceState extends State<ContextLaunchSurface>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final ContextPillPalette palette = ContextPillTheme.paletteFor(widget.semantic);
    final String tooltipMessage =
        widget.tooltip ?? ContextPillTheme.workspaceTooltipFor(widget.semantic);
    final bool interactive = widget.enabled;
    final bool showHoverFx = interactive && _hovering && !ResponsiveHelper.isMobile(context);
    final bool canScale = widget.allowHoverScale && interactive;
    final double scale =
        !canScale ? 1 : (_pressing ? 0.98 : (showHoverFx ? 1.02 : 1));
    final BorderRadius radius =
        widget.borderRadius ?? ContextPillMetrics.resolvedBorderRadius(compact: true);
    final Color borderColor = !interactive
        ? const Color(0xFFE2E8F0)
        : (showHoverFx ? palette.borderHover : palette.border);
    final Color surfaceColor = !interactive
        ? const Color(0xFFF8FAFC)
        : (showHoverFx ? palette.surfaceHover : palette.surface);

    Widget body = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: widget.constraints,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: showHoverFx
                ? ContextPillMetrics.borderWidthHover
                : ContextPillMetrics.borderWidth,
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
            fit: StackFit.passthrough,
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
              widget.child,
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
        label: widget.semanticsLabel ?? tooltipMessage,
        child: MouseRegion(
          onEnter: (_) => _setHover(true),
          onExit: (_) => _setHover(false),
          cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: interactive ? (_) => setState(() => _pressing = true) : null,
            onTapUp: interactive ? (_) => setState(() => _pressing = false) : null,
            onTapCancel: interactive ? () => setState(() => _pressing = false) : null,
            onTap: interactive ? widget.onTap : null,
            child: body,
          ),
        ),
      ),
    );
  }
}
