import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteListScreen extends StatefulWidget {
  final bool isOperator;

  const RouteListScreen({super.key, required this.isOperator});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  // Step 1: fake data, just to see something on screen.
  final List<String> reports = [];

  void _submitReport(String routeName, String issue) {
    setState(() {
      reports.add('$issue on $routeName');
    });
    Navigator.pop(context); // close the dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Report submitted: $issue')));
  }

  void _showReportDialog(BuildContext context, TransitRoute route) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report: ${route.name}'),
          content: const Text('What went wrong?'),
          actions: [
            TextButton(
              onPressed: () => _submitReport(route.name, 'Overcharging'),
              child: const Text('Overcharging'),
            ),
            TextButton(
              onPressed: () => _submitReport(route.name, 'No-show'),
              child: const Text('No-show'),
            ),
            TextButton(
              onPressed: () => _submitReport(route.name, 'Unsafe driving'),
              child: const Text('Unsafe driving'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOperator ? 'Operator View' : 'Commuter View'),
        actions: [
          if (!widget.isOperator)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'View reports',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsScreen(reports: reports),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No routes yet.'));
          }

          final routes = snapshot.data!.docs.map((doc) {
            return TransitRoute.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              Color statusColor;
              String statusLabel;
              switch (route.status) {
                case RouteStatus.active:
                  statusColor = Colors.green;
                  statusLabel = 'Active';
                  break;
                case RouteStatus.off:
                  statusColor = Colors.red;
                  statusLabel = 'Off';
                  break;
                case RouteStatus.full:
                  statusColor = Colors.orange;
                  statusLabel = 'Full';
                  break;
              }

              return ListTile(
                title: Text(route.name),
                subtitle: Text('Fare: \$${route.fare.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(statusLabel),
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: statusColor),
                    ),
                    if (!widget.isOperator)
                      IconButton(
                        icon: const Icon(Icons.flag_outlined),
                        tooltip: 'Report issue',
                        onPressed: () => _showReportDialog(context, route),
                      ),
                  ],
                ),
                onTap: widget.isOperator
                    ? () {
                        FirebaseFirestore.instance
                            .collection('routes')
                            .doc(route.id)
                            .update({'status': route.status.next().name});
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
