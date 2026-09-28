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

  static const TextStyle flowTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.3,
    height: 1.15,
  );

  static const TextStyle helperStyle = TextStyle(
    fontSize: 14,
    color: label,
    height: 1.35,
  );

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 20);
  static const double maxContentWidth = 420;
  static const double webLandingMaxWidth = 1180;

  static const TextStyle heroHeadlineStyle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.8,
    height: 1.08,
  );

  static const TextStyle heroLeadStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: body,
    height: 1.45,
  );

  static const TextStyle landingSectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.3,
    height: 1.15,
  );

  static const TextStyle sectionLeadStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: body,
    height: 1.4,
  );

  static const TextStyle cardLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.2,
  );

  static const TextStyle cardCaptionStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: label,
    height: 1.25,
  );

  static InputDecoration filledField({
    String? hintText,
    Widget? prefixIcon,
    InputBorder? inputBorder,
  }) {
    final OutlineInputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AuthTheme.border),
    );
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      border: inputBorder ?? fieldBorder,
      enabledBorder: inputBorder ?? fieldBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static InputDecoration otpDigitField() {
    return filledField().copyWith(
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}
