import 'package:flutter/material.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'screens/auth/auth_gate.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}
