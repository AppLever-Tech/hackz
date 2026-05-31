import 'package:flutter/material.dart';

import '../menus/hackz_popup_menu.dart';

/// Single-select form field with Hackz premium popup panel styling.
class HackzSelectField<T> extends StatelessWidget {
  const HackzSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hint = 'Select',
    this.enabled = true,
    this.iconBuilder,
    this.prefixIcon,
    this.errorText,
    this.minWidth,
  });

  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;
  final String hint;
  final bool enabled;
  final IconData Function(T option)? iconBuilder;
  final IconData? prefixIcon;
  final String? errorText;
  final double? minWidth;

  static const Color _errorAccent = Color(0xFFBE123C);
  static const Color _errorBorder = Color(0xFFFECACA);
  static const Color _errorFill = Color(0xFFFFF7F7);

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final String displayText = value == null ? hint : labelBuilder(value as T);
    final Color textColor = value == null
        ? const Color(0xFF94A3B8)
        : (enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double panelWidth = minWidth ??
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : HackzPopupMenuStyle.defaultMinWidth);

        return PopupMenuButton<T>(
          enabled: enabled,
          color: HackzPopupMenuStyle.panelColor,
          elevation: 14,
          shadowColor: HackzPopupMenuStyle.panelShadowColor,
          surfaceTintColor: Colors.transparent,
          position: PopupMenuPosition.under,
          offset: HackzPopupMenuStyle.defaultOffset,
          constraints: BoxConstraints(minWidth: panelWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
            side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
          ),
          padding: EdgeInsets.zero,
          onSelected: onChanged,
          itemBuilder: (BuildContext context) {
            return options
                .map(
                  (T option) => PopupMenuItem<T>(
                    value: option,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: HackzPopupMenuItemTile(
                      icon: iconBuilder?.call(option) ?? Icons.label_outline_rounded,
                      label: labelBuilder(option),
                      selected: value == option,
                    ),
                  ),
                )
                .toList(growable: false);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: hasError ? _errorFill : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: 20,
                      color: hasError ? _errorAccent.withValues(alpha: 0.75) : const Color(0xFF64748B),
                    ),
              suffixIcon: Icon(
                enabled ? Icons.expand_more_rounded : Icons.lock_outline_rounded,
                size: 22,
                color: enabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              errorText: hasError ? errorText : null,
              errorStyle: const TextStyle(
                fontSize: 11,
                color: _errorAccent,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
              errorMaxLines: 2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: hasError ? _errorBorder : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFF87171) : const Color(0xFF6A38FF),
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _errorBorder),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.6),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
