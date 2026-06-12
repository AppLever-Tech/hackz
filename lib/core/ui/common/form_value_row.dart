import 'package:flutter/material.dart';

/// Shared label + value row used on dashboard entity cards (ideas, problems).
class FormValueRow extends StatelessWidget {
  const FormValueRow({
    super.key,
    required this.labelWidth,
    required this.child,
    this.label,
    this.labelIcon,
    this.labelStyle = EntityCardStyles.fieldLabel,
    this.labelAlignment = Alignment.centerRight,
    this.labelGap = EntityCardStyles.labelGap,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.labelTopInset = 0,
  });

  final double labelWidth;
  final String? label;
  final IconData? labelIcon;
  final Widget child;
  final TextStyle labelStyle;
  final Alignment labelAlignment;
  final double labelGap;
  final CrossAxisAlignment crossAxisAlignment;
  final double labelTopInset;

  bool get _alignStart => crossAxisAlignment == CrossAxisAlignment.start;

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = label != null && label!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        if (hasLabel)
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: EdgeInsets.only(top: _alignStart ? labelTopInset : 0),
              child: _LabelContent(
                label: label!,
                labelIcon: labelIcon,
                labelStyle: labelStyle,
                labelAlignment: labelAlignment,
              ),
            ),
          ),
        if (hasLabel) SizedBox(width: labelGap),
        Expanded(child: child),
      ],
    );
  }
}

class _LabelContent extends StatelessWidget {
  const _LabelContent({
    required this.label,
    required this.labelIcon,
    required this.labelStyle,
    required this.labelAlignment,
  });

  final String label;
  final IconData? labelIcon;
  final TextStyle labelStyle;
  final Alignment labelAlignment;

  bool get _leftAligned {
    return labelAlignment.x <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final TextAlign textAlign = _leftAligned ? TextAlign.left : TextAlign.right;
    final Text labelText = Text(
      label,
      style: labelStyle,
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (labelIcon == null) return labelText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _leftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: <Widget>[
        Icon(labelIcon, size: 14, color: labelStyle.color),
        const SizedBox(width: 4),
        Flexible(child: labelText),
      ],
    );
  }
}

abstract final class EntityCardStyles {
  static const double labelWidth = 80;
  static const double labelGap = 8;

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle plainValue = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
  );
}
