import 'package:flutter/material.dart';

/// Shared form-style label row for payment summary and detail panes.
class PaymentFormRow extends StatelessWidget {
  const PaymentFormRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.bottomPadding = 9,
  });

  static const double iconWidth = 22;
  static const double labelWidth = 96;

  final IconData icon;
  final String label;
  final Widget value;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: iconWidth,
            child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
          ),
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  static Widget plainValue(String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
    );
  }

  static Widget fallbackAvatar(String displayName, {double radius = 14}) {
    final String trimmed = displayName.trim();
    final String initial = trimmed.isEmpty || trimmed == '—' ? '?' : trimmed.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      child: Text(initial, style: TextStyle(fontSize: radius * 0.78, fontWeight: FontWeight.w800)),
    );
  }
}
