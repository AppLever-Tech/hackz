import 'package:flutter/material.dart';

class AppAlertAction {
  const AppAlertAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool danger;
  final IconData? icon;
}

