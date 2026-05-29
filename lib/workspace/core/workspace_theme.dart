import 'package:flutter/material.dart';

import '../../core/theme/auth_theme.dart';

/// Visual tokens for contextual workspace panels.
abstract final class WorkspaceTheme {
  static const Color ink = AuthTheme.ink;
  static const Color body = AuthTheme.body;
  static const Color muted = AuthTheme.muted;
  static const Color divider = Color(0xFFE8EBF5);
  static const Color scrim = Color(0x4010143B);

  static const double mobileTopRadius = 20;
  static const double panelRadius = 16;

  static double panelWidth(BuildContext context, {required bool isMobile}) {
    if (isMobile) return MediaQuery.sizeOf(context).width;
    final double w = MediaQuery.sizeOf(context).width;
    if (w < 900) return 480;
    return (w.clamp(420, 1200) * 0.38).clamp(420, 520);
  }

  static double mobileSheetHeight(BuildContext context) {
    final double h = MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.paddingOf(context).top;
    return (h - topInset - 24).clamp(h * 0.72, h * 0.94);
  }

  static BoxDecoration panelDecoration({required bool isMobile}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: isMobile
          ? const BorderRadius.vertical(top: Radius.circular(mobileTopRadius))
          : const BorderRadius.horizontal(left: Radius.circular(panelRadius)),
      border: Border.all(color: divider.withValues(alpha: 0.9)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x1A6A38FF),
          blurRadius: 28,
          offset: Offset(-4, 8),
        ),
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static const TextStyle titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: muted,
    height: 1.25,
  );
}
