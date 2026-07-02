import 'package:flutter/material.dart';
import 'models/route_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RouteListScreen(),
    );
  }
}

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  // Step 1: fake data, just to see something on screen.
  final List<TransitRoute> routes = [
    TransitRoute(
      name: 'Harare CBD - Chitungwiza',
      fare: 1.00,
      status: RouteStatus.active,
    ),
    TransitRoute(
      name: 'Harare CBD - Warren Park',
      fare: 1.50,
      status: RouteStatus.off,
    ),
    TransitRoute(
      name: 'Harare CBD - Mabvuku',
      fare: 1.00,
      status: RouteStatus.full,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteWatch')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];

          // Step 1: decide a color based on status
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
            trailing: Chip(
              label: Text(statusLabel),
              backgroundColor: statusColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: statusColor),
            ),
            onTap: () {
              setState(() {
                routes[index] = TransitRoute(
                  name: route.name,
                  fare: route.fare,
                  status: RouteStatus.full,
                );
              });
            },
          );
        },
      ),
    );
  }
}
