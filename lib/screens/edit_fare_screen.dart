import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'auth_gate.dart';

@Deprecated('Use RouteEditor from the authenticated workspace instead.')
class EditFareScreen extends StatelessWidget {
  const EditFareScreen({super.key, required this.route});
  final TransitRoute route;
  @override
  Widget build(BuildContext context) => const AuthGate();
}
