import 'package:flutter/material.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/tenant_session_hooks.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/dashboard/chrome/tenant_business_caches.dart';
import 'core/theme/app_theme.dart';
import 'package:hackz/core/workspace/workspace_host.dart';

Future<void> main() async {
  await FirebaseBootstrap.initialize();
  TenantSessionHooks.addOnRebound(TenantBusinessCaches.clear);
  runApp(const HackzApp());
}

class HackzApp extends StatelessWidget {
  const HackzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hackz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (BuildContext context, Widget? child) {
        return WorkspaceHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}
