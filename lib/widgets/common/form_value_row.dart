import 'package:flutter/material.dart';

/// Shared label + value row used on dashboard entity cards (ideas, problems).
class FormValueRow extends StatelessWidget {
  const FormValueRow({
    super.key,
    required this.labelWidth,
    required this.child,
    this.label,
    this.labelStyle = EntityCardStyles.fieldLabel,
  });

  final double labelWidth;
  final String? label;
  final Widget child;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: label == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label!, style: labelStyle),
                ),
        ),
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
  static const double labelWidth = 72;

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
