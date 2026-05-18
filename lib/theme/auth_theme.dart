import 'package:flutter/material.dart';

/// Shared colors and gradients for auth / landing flows.
abstract final class AuthTheme {
  static const Color ink = Color(0xFF10143B);
  static const Color body = Color(0xFF43486A);
  static const Color muted = Color(0xFF64748B);
  static const Color label = Color(0xFF515777);
  static const Color border = Color(0xFFD4D8F1);
  static const Color outline = Color(0xFFA5ABD0);

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFEDEBFF),
      Color(0xFFF7ECFF),
      Color(0xFFF9F1FF),
    ],
  );

  static const LinearGradient primaryButton = LinearGradient(
    colors: <Color>[Color(0xFF6A38FF), Color(0xFFFF8C2B)],
  );

  static const double buttonHeight = 52;
  static const double buttonRadius = 12;

  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: body,
    height: 1.35,
  );

  static const TextStyle featureTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const TextStyle footerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: muted,
  );
}
