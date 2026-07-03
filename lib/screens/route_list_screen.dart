import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'reports_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_route_screen.dart';
import 'edit_fare_screen.dart';

class RouteListScreen extends StatefulWidget {
  final bool isOperator;

  const RouteListScreen({super.key, required this.isOperator});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  bool _sortByFare = false;

  void _submitReport(String routeName, String issue) {
    FirebaseFirestore.instance.collection('reports').add({
      'routeName': routeName,
      'issue': issue,
      'timestamp': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
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

  Future<bool> _confirmDeleteReturnsBool(
    BuildContext context,
    TransitRoute route,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete route?'),
          content: Text('This will permanently remove "${route.name}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(route.id)
          .delete();
      return true;
    }
    return false;
  }

  void _openEditFare(BuildContext context, TransitRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditFareScreen(route: route)),
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
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(_sortByFare ? Icons.sort : Icons.sort_by_alpha),
            tooltip: 'Sort by fare',
            onPressed: () {
              setState(() => _sortByFare = !_sortByFare);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: widget.isOperator
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRouteScreen(),
                  ),
                );
              },
              tooltip: 'Add Route',
              child: const Icon(Icons.add),
            )
          : null,
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
          if (_sortByFare) {
            routes.sort((a, b) => a.fare.compareTo(b.fare));
          }
          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              final isOwner = route.ownerId == currentUid;

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

              final canManage = widget.isOperator && isOwner;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('routes')
                    .doc(route.id)
                    .collection('passengers')
                    .snapshots(),
                builder: (context, passengerSnapshot) {
                  final passengerDocs = passengerSnapshot.data?.docs ?? [];
                  final onboardCount = passengerDocs.length;
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;
                  final isOnboard = passengerDocs.any(
                    (doc) => doc.id == currentUid,
                  );
                  final seatsLeft = route.capacity - onboardCount;

                  return Dismissible(
                    key: Key(route.id),
                    direction: canManage
                        ? DismissDirection.horizontal
                        : DismissDirection.none,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        return await _confirmDeleteReturnsBool(context, route);
                      } else {
                        _openEditFare(context, route);
                        return false;
                      }
                    },
                    background: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Opacity(
                      opacity: widget.isOperator && !isOwner ? 0.5 : 1.0,
                      child: ListTile(
                        title: Text(route.name),
                        subtitle: Text(
                          'Fare: \$${route.fare.toStringAsFixed(2)} • '
                          '$onboardCount/${route.capacity} onboard'
                          '${route.ownerId != null && !isOwner ? " • ${route.company ?? "Unknown company"}" : ""}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(statusLabel),
                              backgroundColor: statusColor.withValues(
                                alpha: 0.2,
                              ),
                              labelStyle: TextStyle(color: statusColor),
                            ),
                            if (widget.isOperator && !isOwner)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.lock_outline, size: 18),
                              ),
                            if (!widget.isOperator)
                              IconButton(
                                icon: Icon(
                                  isOnboard
                                      ? Icons.directions_bus
                                      : Icons.directions_bus_outlined,
                                  color: isOnboard ? Colors.green : null,
                                ),
                                tooltip: isOnboard
                                    ? 'Leave route'
                                    : 'Board route',
                                onPressed: seatsLeft <= 0 && !isOnboard
                                    ? null
                                    : () {
                                        final passengerRef = FirebaseFirestore
                                            .instance
                                            .collection('routes')
                                            .doc(route.id)
                                            .collection('passengers')
                                            .doc(currentUid);

                                        if (isOnboard) {
                                          passengerRef.delete();
                                        } else {
                                          passengerRef.set({
                                            'boardedAt':
                                                FieldValue.serverTimestamp(),
                                          });
                                        }
                                      },
                              ),
                            if (!widget.isOperator)
                              IconButton(
                                icon: const Icon(Icons.flag_outlined),
                                tooltip: 'Report issue',
                                onPressed: () =>
                                    _showReportDialog(context, route),
                              ),
                          ],
                        ),
                        onTap: canManage
                            ? () {
                                FirebaseFirestore.instance
                                    .collection('routes')
                                    .doc(route.id)
                                    .update({
                                      'status': route.status.next().name,
                                    });
                              }
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
