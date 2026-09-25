import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    super.key,
    required this.page,
    required this.labels,
    required this.network,
    required this.onSelect,
    required this.onSignOut,
  });
  final int page;
  final List<String> labels;
  final bool network;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;
  @override
  Widget build(BuildContext context) => Material(
    color: ink,
    child: Container(
      width: 236,

      padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route, color: Color(0xFFC6E59B), size: 30),
              SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'smarttransit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 40, top: 5),
            child: Text(
              'Z I M B A B W E',
              style: TextStyle(color: Color(0xFF93B2A3), fontSize: 9),
            ),
          ),
          const SizedBox(height: 52),
          const Text(
            'YOUR WORKSPACE',
            style: TextStyle(
              color: Color(0xFF93B2A3),
              fontSize: 10,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: page == i,
                selectedTileColor: const Color(0xFF2E4A3E),
                selectedColor: const Color(0xFFD2EAAE),
                textColor: const Color(0xFFC0CFC6),
                iconColor: const Color(0xFFC0CFC6),
                leading: Icon(
                  [
                    Icons.route_outlined,
                    network ? Icons.public : Icons.bookmark_border,
                    Icons.flag_outlined,
                  ][i],
                  size: 20,
                ),
                title: Text(labels[i], style: const TextStyle(fontSize: 13)),
                onTap: () => onSelect(i),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF203C32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, color: Color(0xFFC6E59B)),
                SizedBox(height: 12),
                Text(
                  'A better way to move.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Every shared journey brings our cities closer.',
                  style: TextStyle(
                    color: Color(0xFFA8BEB2),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC0CFC6),
            ),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}
