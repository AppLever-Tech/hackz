import 'package:flutter/material.dart';

import '../../../../core/theme/auth_theme.dart';

/// Compact premium innovation milestone for the sequential journey grid.
class InnovationMilestoneNode extends StatefulWidget {
  const InnovationMilestoneNode({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    this.scale = 1,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final double scale;

  static const double width = 78;
  static const double height = 54;

  @override
  State<InnovationMilestoneNode> createState() => _InnovationMilestoneNodeState();
}

class _InnovationMilestoneNodeState extends State<InnovationMilestoneNode> {
  bool _hovered = false;

  Color get _softAccent =>
      Color.lerp(widget.accent, Colors.white, 0.38) ?? widget.accent;

  @override
  Widget build(BuildContext context) {
    final double w = InnovationMilestoneNode.width * widget.scale;
    final double h = InnovationMilestoneNode.height * widget.scale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.white.withValues(alpha: _hovered ? 0.96 : 0.9),
              _softAccent.withValues(alpha: _hovered ? 0.1 : 0.06),
            ],
          ),
          border: Border.all(
            color: _softAccent.withValues(alpha: _hovered ? 0.32 : 0.2),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _softAccent.withValues(alpha: _hovered ? 0.12 : 0.06),
              blurRadius: _hovered ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(widget.icon, size: 19 * widget.scale, color: _softAccent),
            SizedBox(height: 4 * widget.scale),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuthTheme.cardLabelStyle.copyWith(
                fontSize: 10.5 * widget.scale,
                fontWeight: FontWeight.w600,
                color: AuthTheme.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edge anchor points for connector attachment (flush to node bounds).
abstract final class MilestoneAnchors {
  static Offset enterLeft(Offset topLeft, double scale) {
    final double h = InnovationMilestoneNode.height * scale;
    return Offset(topLeft.dx, topLeft.dy + h / 2);
  }

  static Offset exitRight(Offset topLeft, double scale) {
    final double w = InnovationMilestoneNode.width * scale;
    final double h = InnovationMilestoneNode.height * scale;
    return Offset(topLeft.dx + w, topLeft.dy + h / 2);
  }

  static Offset enterTop(Offset topLeft, double scale) {
    final double w = InnovationMilestoneNode.width * scale;
    return Offset(topLeft.dx + w / 2, topLeft.dy);
  }

  static Offset exitBottom(Offset topLeft, double scale) {
    final double w = InnovationMilestoneNode.width * scale;
    final double h = InnovationMilestoneNode.height * scale;
    return Offset(topLeft.dx + w / 2, topLeft.dy + h);
  }

  static Offset exitLeft(Offset topLeft, double scale) {
    final double h = InnovationMilestoneNode.height * scale;
    return Offset(topLeft.dx, topLeft.dy + h / 2);
  }

  static Offset enterRight(Offset topLeft, double scale) {
    final double w = InnovationMilestoneNode.width * scale;
    final double h = InnovationMilestoneNode.height * scale;
    return Offset(topLeft.dx + w, topLeft.dy + h / 2);
  }
}
