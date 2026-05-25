import 'package:flutter/material.dart';

import '../../theme/auth_theme.dart';

/// Full-screen auth-gradient shell with safe area (no scroll — child manages layout).
class MobileLandingShell extends StatelessWidget {
  const MobileLandingShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AuthTheme.pageBackground),
        child: SafeArea(child: child),
      ),
    );
  }
}
