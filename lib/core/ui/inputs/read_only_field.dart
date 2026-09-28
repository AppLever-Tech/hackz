import 'package:flutter/material.dart';

class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.value,
    this.hintText = '',
    this.helperText,
    this.suffixIcon,
    /// Tighter padding and no helper under the field (e.g. paired rows).
    this.compact = false,
  });

  final String value;
  final String hintText;
  final String? helperText;
  final Widget? suffixIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        hintText: hintText,
        helperText: compact ? null : helperText,
        isDense: compact,
        filled: true,
        fillColor: const Color(0xFFF2F0F8),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD2C8EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              value.isEmpty ? hintText : value,
              style: TextStyle(
                color: value.isEmpty ? const Color(0xFF7A7FA3) : const Color(0xFF202658),
                fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}
