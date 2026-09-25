import 'package:flutter/material.dart';
import 'auth_gate.dart';

/// Roles are read from the authenticated profile, never from this legacy flag.
@Deprecated('Use AuthGate and the role-aware workspace instead.')
class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key, required this.isOperator});
  final bool isOperator;
  @override
  Widget build(BuildContext context) => const AuthGate();
}
