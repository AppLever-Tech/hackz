import 'package:flutter/material.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  await FirebaseBootstrap.initialize();
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
      home: const AuthGate(),
    );
  }
}
