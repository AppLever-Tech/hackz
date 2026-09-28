import 'package:flutter/material.dart';

import '../menus/hackz_popup_menu.dart';
import 'hackz_input_decoration.dart';

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
    this.compact = false,
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
  final bool compact;
  final IconData Function(T option)? iconBuilder;
  final IconData? prefixIcon;
  final String? errorText;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final String displayText = value == null ? hint : labelBuilder(value as T);
    final Color textColor = value == null
        ? HackzInputDecoration.hintColor
        : (enabled ? const Color(0xFF0F172A) : HackzInputDecoration.hintColor);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double panelWidth = minWidth ??
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : HackzPopupMenuStyle.defaultMinWidth);

        return PopupMenuButton<T>(
          enabled: enabled,
          tooltip: displayText,
          color: HackzPopupMenuStyle.panelColor,
          elevation: 14,
          shadowColor: HackzPopupMenuStyle.panelShadowColor,
          surfaceTintColor: Colors.transparent,
          position: PopupMenuPosition.under,
          offset: HackzPopupMenuStyle.defaultOffset,
          constraints: compact
              ? BoxConstraints(minWidth: panelWidth, maxWidth: panelWidth)
              : BoxConstraints(minWidth: panelWidth),
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
                    height: compact ? 36 : 38,
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
            decoration: HackzInputDecoration.decorate(
              compact: compact,
              errorText: hasError ? errorText : null,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: compact ? 18 : 20,
                      color: hasError
                          ? HackzInputDecoration.errorColor.withValues(alpha: 0.75)
                          : HackzInputDecoration.iconColor,
                    ),
              suffixIcon: Icon(
                enabled ? Icons.expand_more_rounded : Icons.lock_outline_rounded,
                size: compact ? 20 : 22,
                color: enabled ? HackzInputDecoration.iconColor : HackzInputDecoration.hintColor,
              ),
              contentPaddingOverride: compact
                  ? HackzInputDecoration.compactContentPadding
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
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
