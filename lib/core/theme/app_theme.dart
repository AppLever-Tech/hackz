import 'package:flutter/material.dart';

/// App-wide theme using system UI fonts (avoids Roboto CDN fetch on Flutter Web).
abstract final class AppTheme {
  static const String fontFamily = 'Segoe UI';
  static const List<String> fontFamilyFallback = <String>[
    'system-ui',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A38FF),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      textTheme: Typography.material2021(platform: TargetPlatform.windows)
          .black
          .apply(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFamilyFallback,
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
    );
  }
}
