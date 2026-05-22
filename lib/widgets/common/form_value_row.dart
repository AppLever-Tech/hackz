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
  });

  final double labelWidth;
  final String? label;
  final IconData? labelIcon;
  final Widget child;
  final TextStyle labelStyle;
  final Alignment labelAlignment;
  final double labelGap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = label != null && label!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: hasLabel
              ? Align(
                  alignment: labelAlignment,
                  child: _LabelContent(
                    label: label!,
                    labelIcon: labelIcon,
                    labelStyle: labelStyle,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (hasLabel) SizedBox(width: labelGap),
        Expanded(
          child: Align(
            alignment: crossAxisAlignment == CrossAxisAlignment.start
                ? Alignment.topLeft
                : Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _LabelContent extends StatelessWidget {
  const _LabelContent({
    required this.label,
    required this.labelIcon,
    required this.labelStyle,
  });

  final String label;
  final IconData? labelIcon;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final Text labelText = Text(
      label,
      style: labelStyle,
      textAlign: TextAlign.right,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (labelIcon == null) return labelText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
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
