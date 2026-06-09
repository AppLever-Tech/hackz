import 'package:flutter/material.dart';

import 'responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart' show SectionContainer;

/// Section block with responsive padding; reuses premium [SectionContainer] styling.
class ResponsiveSection extends StatelessWidget {
  const ResponsiveSection({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (ResponsiveHelper.isMobile(context) ? 12 : 16);
    final content = SectionContainer(
      padding: padding ?? EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 12 : 14),
      borderRadius: radius,
      child: child,
    );

    if (title == null || title!.trim().isEmpty) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title!,
          style: TextStyle(
            fontSize: ResponsiveHelper.isMobile(context) ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: ResponsiveHelper.isMobile(context) ? 8 : 10),
        content,
      ],
    );
  }
}
