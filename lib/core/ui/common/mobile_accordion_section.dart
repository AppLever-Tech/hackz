import 'package:flutter/material.dart';

/// Shared mobile accordion header styling (manage users role groups, eval assignments, etc.).
abstract final class MobileAccordionSectionMetrics {
  MobileAccordionSectionMetrics._();

  static const Color headerBackground = Color(0xFFF6F8FD);
  static const Color bodyBackground = Colors.white;
  static const Color borderColor = Color(0xFFD9E2F5);
  static const double borderWidth = 1.2;
  static const double borderRadius = 10;
  static const EdgeInsets headerPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: Color(0xFF0F172A),
  );
}

class MobileAccordionSection extends StatelessWidget {
  const MobileAccordionSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
    this.leading,
    this.titleTrailing,
    this.bodyHeight,
  });

  final String title;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;
  final Widget? leading;
  final Widget? titleTrailing;
  final double? bodyHeight;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(MobileAccordionSectionMetrics.borderRadius);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: MobileAccordionSectionMetrics.bodyBackground,
          borderRadius: radius,
          border: Border.all(
            color: MobileAccordionSectionMetrics.borderColor,
            width: MobileAccordionSectionMetrics.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ColoredBox(
              color: MobileAccordionSectionMetrics.headerBackground,
              child: Padding(
                padding: MobileAccordionSectionMetrics.headerPadding,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () => onExpandedChanged(!expanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: <Widget>[
                            if (leading != null) ...<Widget>[
                              leading!,
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(title, style: MobileAccordionSectionMetrics.titleStyle),
                            ),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...<Widget>[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
              ),
            ),
            if (expanded) ...<Widget>[
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              if (bodyHeight != null)
                SizedBox(height: bodyHeight, child: child)
              else
                child,
            ],
          ],
        ),
      ),
    );
  }
}
