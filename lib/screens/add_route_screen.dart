import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _capacityController = TextEditingController();
  final _nameController = TextEditingController();
  final _fareController = TextEditingController();
  bool _isSaving = false;

  // ---- Design tokens (LeafLight-inspired) ----
  static const Color _bg = Color(0xFFF3F5F9);
  static const List<Color> _heroGradient = [
    Color(0xFF0D3B84),
    Color(0xFF1E70C7),
  ];

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveRoute() async {
    final name = _nameController.text.trim();
    final fareText = _fareController.text.trim();
    final capacityText = _capacityController.text.trim();
    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      _showToast('Please enter a valid capacity.');
      return;
    }

    if (name.isEmpty || fareText.isEmpty) {
      _showToast('Please fill in both fields.');
      return;
    }

    final fare = double.tryParse(fareText);
    if (fare == null || fare <= 0) {
      _showToast('Please enter a valid fare amount.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final company = userDoc.data()?['company'] as String? ?? 'Unknown';

      await FirebaseFirestore.instance.collection('routes').add({
        'name': name,
        'fare': fare,
        'status': 'active',
        'company': company,
        'ownerId': uid,
        'capacity': capacity,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: _heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text('Add Route'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: _heroGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_road,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Route',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Fill in the details below to publish it live',
                                style: TextStyle(
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
                  const SizedBox(height: 16),
                  // Form card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: _fieldDecoration(
                            label: 'Route name',
                            icon: Icons.route,
                            hint: 'e.g. Harare CBD - Highfield',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _fareController,
                          decoration: _fieldDecoration(
                            label: 'Fare (USD)',
                            icon: Icons.attach_money,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _capacityController,
                          decoration: _fieldDecoration(
                            label: 'Vehicle capacity (seats)',
                            icon: Icons.event_seat,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isSaving
                            ? null
                            : const LinearGradient(
                                colors: _heroGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: _isSaving ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isSaving
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E70C7,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isSaving ? null : _saveRoute,
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF1565C0),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Save Route',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
