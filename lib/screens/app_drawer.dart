import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  AppDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
}

class AppDrawer extends StatelessWidget {
  final String roleLabel;
  final List<AppDrawerItem> items;

  const AppDrawer({super.key, required this.roleLabel, required this.items});

  static const List<Color> _heroGradient = [
    Color(0xFF0D3B84),
    Color(0xFF1E70C7),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: _heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (email != null && email.isNotEmpty)
                          ? email[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) {
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: item.selected
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade600,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: item.selected
                            ? const Color(0xFF1565C0)
                            : Colors.black87,
                        fontWeight: item.selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: item.selected,
                    selectedTileColor: const Color(0xFFE3F2FD),
                    onTap: () {
                      Navigator.pop(context);
                      item.onTap();
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
