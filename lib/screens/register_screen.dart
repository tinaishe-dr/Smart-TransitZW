import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  String _selectedRole = 'commuter'; // default choice
  bool _isLoading = false;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final company = _companyController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast('Please fill in both email and password.');
      return;
    }
    if (password.length < 6) {
      _showToast('Password must be at least 6 characters.');
      return;
    }
    if (_selectedRole == 'operator' && company.isEmpty) {
      _showToast('Please enter your company name.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'email': email,
            'role': _selectedRole,
            if (_selectedRole == 'operator') 'company': company,
          });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showToast(e.message ?? 'Registration failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('I am a:'),
              ),
              RadioGroup<String>(
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value!);
                },
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Commuter'),
                      value: 'commuter',
                    ),
                    RadioListTile<String>(
                      title: Text('Operator'),
                      value: 'operator',
                    ),
                  ],
                ),
              ),
              if (_selectedRole == 'operator') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _companyController,
                  decoration: const InputDecoration(labelText: 'Company name'),
                ),
              ],
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Register'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
