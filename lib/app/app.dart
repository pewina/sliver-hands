import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'app_theme.dart';

class SilverHandsApp extends StatelessWidget {
  const SilverHandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SilverHands',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
