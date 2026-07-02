import 'package:flutter/material.dart';
import 'route_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTransitZW')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const RouteListScreen(isOperator: false),
                  ),
                );
              },
              child: const Text('I am a Commuter'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const RouteListScreen(isOperator: true),
                  ),
                );
              },
              child: const Text('I am an Operator'),
            ),
          ],
        ),
      ),
    );
  }
}
