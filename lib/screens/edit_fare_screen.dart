import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route_model.dart';

class EditFareScreen extends StatefulWidget {
  final TransitRoute route;

  const EditFareScreen({super.key, required this.route});

  @override
  State<EditFareScreen> createState() => _EditFareScreenState();
}

class _EditFareScreenState extends State<EditFareScreen> {
  late final TextEditingController _fareController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fareController = TextEditingController(
      text: widget.route.fare.toStringAsFixed(2),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveFare() async {
    final fare = double.tryParse(_fareController.text.trim());
    if (fare == null || fare <= 0) {
      _showToast('Please enter a valid fare amount.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.route.id)
          .update({'fare': fare});
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
      appBar: AppBar(title: Text('Edit fare: ${widget.route.name}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  onPressed: _saveFare,
                  child: const Text('Save Fare'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
