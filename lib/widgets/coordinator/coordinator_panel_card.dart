import 'package:flutter/material.dart';

class CoordinatorPanelCard extends StatelessWidget {
  const CoordinatorPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.backgroundColor = Colors.white,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14273B6A), blurRadius: 22, offset: Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }
}
