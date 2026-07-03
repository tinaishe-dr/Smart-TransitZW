import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_list_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('No role found for this account.')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] as String;

        switch (role) {
          case 'admin':
            return const AdminDashboardScreen();
          case 'operator':
            return const RouteListScreen(isOperator: true);
          default:
            return const RouteListScreen(isOperator: false);
        }
      },
    );
  }
}
