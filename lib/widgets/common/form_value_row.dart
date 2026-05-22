import 'package:flutter/material.dart';

/// Shared label + value row used on dashboard entity cards (ideas, problems).
class FormValueRow extends StatelessWidget {
  const FormValueRow({
    super.key,
    required this.labelWidth,
    required this.child,
    this.label,
    this.labelStyle = EntityCardStyles.fieldLabel,
    this.labelAlignment = Alignment.centerRight,
    this.labelGap = EntityCardStyles.labelGap,
  });

  final double labelWidth;
  final String? label;
  final Widget child;
  final TextStyle labelStyle;
  final Alignment labelAlignment;
  final double labelGap;

  @override
  Widget build(BuildContext context) {
    final bool hasLabel = label != null && label!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: hasLabel
              ? Align(
                  alignment: labelAlignment,
                  child: Text(
                    label!,
                    style: labelStyle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (hasLabel) SizedBox(width: labelGap),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
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
