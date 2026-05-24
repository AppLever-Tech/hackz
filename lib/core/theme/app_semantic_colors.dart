import 'package:flutter/material.dart';

/// Semantic surface styles for pills, chips, and contextual UI (parallel to [AppIcons]).
abstract final class AppSemanticColors {
  AppSemanticColors._();

  // —— Status pills (informational, muted fill) ——
  static const Color statusSurface = Color(0xFFF1F5F9);
  static const Color statusBorder = Color(0xFFE2E8F0);
  static const Color statusText = Color(0xFF475569);

  // —— Metric pills (neutral informational) ——
  static const Color metricSurface = Color(0xFFF8FAFC);
  static const Color metricBorder = Color(0xFFE2E8F0);
  static const Color metricText = Color(0xFF64748B);

  // —— Context pills (interactive workspace navigation) ——
  static const ContextPillPalette contextGeneric = ContextPillPalette(
    border: Color(0xFFCBD5E1),
    borderHover: Color(0xFF818CF8),
    surface: Color(0xFFF8FAFF),
    surfaceHover: Color(0xFFEEF2FF),
    text: Color(0xFF3730A3),
    glow: Color(0x336366F1),
  );

  static const ContextPillPalette contextUser = ContextPillPalette(
    border: Color(0xFFBFDBFE),
    borderHover: Color(0xFF60A5FA),
    surface: Color(0xFFF0F9FF),
    surfaceHover: Color(0xFFE0F2FE),
    text: Color(0xFF1D4ED8),
    glow: Color(0x332563EB),
  );

  static const ContextPillPalette contextTeam = ContextPillPalette(
    border: Color(0xFFC7D2FE),
    borderHover: Color(0xFF818CF8),
    surface: Color(0xFFF5F3FF),
    surfaceHover: Color(0xFFEDE9FE),
    text: Color(0xFF5B21B6),
    glow: Color(0x337C3AED),
  );

  static const ContextPillPalette contextIdea = ContextPillPalette(
    border: Color(0xFFC4B5FD),
    borderHover: Color(0xFFA78BFA),
    surface: Color(0xFFF5F3FF),
    surfaceHover: Color(0xFFEDE9FE),
    text: Color(0xFF6D28D9),
    glow: Color(0x338B5CF6),
  );

  static const ContextPillPalette contextProblem = ContextPillPalette(
    border: Color(0xFFA5B4FC),
    borderHover: Color(0xFF6366F1),
    surface: Color(0xFFEEF2FF),
    surfaceHover: Color(0xFFE0E7FF),
    text: Color(0xFF4338CA),
    glow: Color(0x334F46E5),
  );

  static const ContextPillPalette contextPayment = ContextPillPalette(
    border: Color(0xFF99F6E4),
    borderHover: Color(0xFF2DD4BF),
    surface: Color(0xFFF0FDFA),
    surfaceHover: Color(0xFFCCFBF1),
    text: Color(0xFF0F766E),
    glow: Color(0x3314B8A6),
  );

  static const ContextPillPalette contextEvaluation = ContextPillPalette(
    border: Color(0xFFFCD34D),
    borderHover: Color(0xFFF59E0B),
    surface: Color(0xFFFFFBEB),
    surfaceHover: Color(0xFFFEF3C7),
    text: Color(0xFFB45309),
    glow: Color(0x33F59E0B),
  );

  // —— Semantic states ——
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);

  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFFB45309);

  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorText = Color(0xFFB91C1C);
}

/// Outlined accent palette for a [ContextPill] entity type.
class ContextPillPalette {
  const ContextPillPalette({
    required this.border,
    required this.borderHover,
    required this.surface,
    required this.surfaceHover,
    required this.text,
    required this.glow,
  });

  final Color border;
  final Color borderHover;
  final Color surface;
  final Color surfaceHover;
  final Color text;
  final Color glow;
}
