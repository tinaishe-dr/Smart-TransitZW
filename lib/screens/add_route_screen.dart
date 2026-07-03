import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _nameController = TextEditingController();
  final _fareController = TextEditingController();
  bool _isSaving = false;

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveRoute() async {
    final name = _nameController.text.trim();
    final fareText = _fareController.text.trim();

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
      await FirebaseFirestore.instance.collection('routes').add({
        'name': name,
        'fare': fare,
        'status': 'active',
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showToast('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Route')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Route name (e.g. Harare CBD - Highfield)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fareController,
                decoration: const InputDecoration(labelText: 'Fare (USD)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _saveRoute,
                  child: const Text('Save Route'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
