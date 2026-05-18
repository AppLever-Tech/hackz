import 'package:flutter/material.dart';

import '../../theme/auth_theme.dart';

/// White inset field shell used on auth form screens (phone, OTP row parent, etc.).
class AuthFieldContainer extends StatelessWidget {
  const AuthFieldContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.border),
      ),
      child: child,
    );
  }
}
