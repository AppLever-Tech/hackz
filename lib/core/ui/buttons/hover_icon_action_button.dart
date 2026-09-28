import 'package:flutter/material.dart';

/// Circular icon action with border/background visible only on hover.
class HoverIconActionButton extends StatefulWidget {
  const HoverIconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
    this.iconSize = 15,
    this.size = 28,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;
  final double iconSize;
  final double size;
  final Color? iconColor;

  @override
  State<HoverIconActionButton> createState() => _HoverIconActionButtonState();
}

class _HoverIconActionButtonState extends State<HoverIconActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        widget.destructive ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0);
    final Color resolvedIconColor = widget.iconColor ??
        (widget.destructive ? const Color(0xFFDC2626) : const Color(0xFF64748B));
    final Color backgroundColor =
        widget.destructive ? const Color(0xFFFFF7F7) : Colors.white;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: _hovering ? backgroundColor : Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(color: _hovering ? borderColor : Colors.transparent),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(widget.icon, size: widget.iconSize, color: resolvedIconColor),
            ),
          ),
        ),
      ),
    );
  }
}
