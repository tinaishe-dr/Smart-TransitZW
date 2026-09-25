import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/account_screen.dart';
import '../features/transit_dashboard.dart';
import '../data/transit_repository.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.uid});
  final String uid;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _profile = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.uid)
      .snapshots();
  late final _repository = TransitRepository(
    FirebaseFirestore.instance,
    widget.uid,
  );
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: _profile,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyState(
                  title: 'Account unavailable',
                  message: 'Check your connection and database permissions.',
                ),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Return to sign in'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.data!.exists) {
        return const AccountScreen(completeProfile: true);
      }
      final profile = snapshot.data!.data()!;
      return TransitDashboard(
        repository: _repository,
        role: profile['role'] as String? ?? 'commuter',
        company: profile['company'] as String? ?? '',
      );
    },
  );
}
