import 'package:flutter/material.dart';
import 'auth_gate.dart';

/// Legacy entry point. The authenticated workspace owns navigation and permissions.
@Deprecated('Use AuthGate and the role-aware workspace instead.')
class AddRouteScreen extends StatelessWidget {
  const AddRouteScreen({super.key});
  @override
  Widget build(BuildContext context) => const AuthGate();
}
