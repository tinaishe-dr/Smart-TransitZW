import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  final List<String> reports;

  const ReportsScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: reports.isEmpty
          ? const Center(child: Text('No reports yet.'))
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(reports[index]),
                );
              },
            ),
    );
  }
}
