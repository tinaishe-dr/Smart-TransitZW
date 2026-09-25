import 'package:flutter/material.dart';
import 'auth_gate.dart';

/// Compatibility entry point. Authentication and role selection are centralised.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthGate();
}
