import 'package:flutter/material.dart';

/// Shared Hackz form-field chrome — rounded corners, soft fill, purple focus.
///
/// Use for TextFields, select triggers, and date/time pickers so screens share
/// one look (problem authoring, ideathon create, etc.).
abstract final class HackzInputDecoration {
  HackzInputDecoration._();

  static const Color fillColor = Color(0xFFFCFDFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color focusColor = Color(0xFF6A38FF);
  static const Color labelColor = Color(0xFF334155);
  static const Color hintColor = Color(0xFF94A3B8);
  static const Color textColor = Color(0xFF1E293B);
  static const Color iconColor = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFBE123C);
  static const Color errorBorderColor = Color(0xFFFECACA);
  static const Color errorFillColor = Color(0xFFFFF7F7);

  static const double radius = 12;
  static const double focusWidth = 1.4;
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);

  static const TextStyle labelStyle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: labelColor,
    letterSpacing: 0.1,
  );

  static const TextStyle fieldTextStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: textColor,
  );

  static OutlineInputBorder border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color ?? borderColor, width: width),
    );
  }

  static OutlineInputBorder get enabledBorder => border();

  static OutlineInputBorder get focusedBorder => border(color: focusColor, width: focusWidth);

  static OutlineInputBorder get errorBorder => border(color: errorBorderColor);

  static OutlineInputBorder get focusedErrorBorder =>
      border(color: const Color(0xFFF87171), width: focusWidth);

  /// Standard [InputDecoration] matching problem-authoring fields.
  static InputDecoration decorate({
    String? hintText,
    String? labelText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool dense = true,
    bool filled = true,
    Color? fillColorOverride,
    EdgeInsetsGeometry? contentPaddingOverride,
  }) {
    final bool hasError = errorText != null && errorText.trim().isNotEmpty;
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      errorText: hasError ? errorText : null,
      hintStyle: TextStyle(color: Colors.grey.shade500, height: 1.4),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: hasError ? errorFillColor : (fillColorOverride ?? fillColor),
      isDense: dense,
      contentPadding: contentPaddingOverride ?? contentPadding,
      border: enabledBorder,
      enabledBorder: hasError ? errorBorder : enabledBorder,
      focusedBorder: hasError ? focusedErrorBorder : focusedBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: focusedErrorBorder,
      errorStyle: const TextStyle(
        fontSize: 11,
        color: errorColor,
        height: 1.25,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
    );
  }

  /// Non-text picker chrome (date/time) matching field borders.
  static BoxDecoration pickerDecoration({bool emphasized = false}) {
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: emphasized ? focusColor : borderColor,
        width: emphasized ? focusWidth : 1,
      ),
    );
  }
}
