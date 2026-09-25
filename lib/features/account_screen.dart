import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.completeProfile = false});
  final bool completeProfile;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _company = TextEditingController();
  bool _register = false, _busy = false, _obscure = true;
  String _role = 'commuter';
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final role = _role;
    final company = _company.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (widget.completeProfile || _register) {
        final user = widget.completeProfile
            ? auth.currentUser!
            : (await auth.createUserWithEmailAndPassword(
                email: _email.text.trim(),
                password: _password.text,
              )).user!;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': role,
          'company': role == 'operator' ? company : '',
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.code) {
            'invalid-credential' => 'The email or password is incorrect.',
            'email-already-in-use' =>
              'This email already has an account. Sign in instead.',
            'network-request-failed' =>
              'No connection. Please try again when you are online.',
            'too-many-requests' =>
              'Too many attempts. Please wait and try again.',
            _ => e.message ?? 'Unable to sign in. Please try again.',
          },
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_email.text.contains('@')) {
      showMessage(context, 'Enter your email address first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );
      if (mounted) {
        showMessage(
          context,
          'If an account exists, a password reset email has been sent.',
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not send a reset email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _register || widget.completeProfile;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, size) => Row(
          children: [
            if (size.maxWidth >= 1100 && size.maxHeight >= 780)
              Expanded(
                child: Container(
                  color: ink,
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.route, color: Color(0xFFC6E59B), size: 34),
                          SizedBox(width: 12),
                          Text(
                            'smarttransit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const StatusPill(
                        'BUILT FOR ZIMBABWE',
                        color: Color(0xFFC6E59B),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Better journeys.\nConnected communities.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your daily commute, with a little more certainty.\nConnecting passengers, operators and the people who plan our cities.',
                        style: TextStyle(
                          color: Color(0xFFBDD0C5),
                          fontSize: 17,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Row(
                        children: [
                          Icon(
                            Icons.directions_bus_outlined,
                            color: Color(0xFFC6E59B),
                            size: 56,
                          ),
                          SizedBox(width: 24),
                          Expanded(
                            child: Text(
                              'One network.\nMore possibilities.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'MOVING ZIMBABWE, TOGETHER',
                        style: TextStyle(
                          color: Color(0xFFBDD0C5),
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: AutofillGroup(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.route, color: forest, size: 40),
                            const SizedBox(height: 32),
                            Text(
                              widget.completeProfile
                                  ? 'Finish your account'
                                  : creating
                                  ? 'Let’s get you moving.'
                                  : 'Welcome back.',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              creating
                                  ? 'Choose how you’ll use SmartTransitZW.'
                                  : 'Sign in for a smoother journey.',
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 30),
                            if (!widget.completeProfile) ...[
                              TextFormField(
                                controller: _email,
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                ),
                                validator: (v) =>
                                    v != null &&
                                        RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(v.trim())
                                    ? null
                                    : 'Enter a valid email',
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: [
                                  creating
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    tooltip: _obscure
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Use at least 6 characters'
                                    : null,
                              ),
                            ],
                            if (creating) ...[
                              const SizedBox(height: 22),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'commuter',
                                    label: Text('Commuter'),
                                    icon: Icon(Icons.person_outline),
                                  ),
                                  ButtonSegment(
                                    value: 'operator',
                                    label: Text('Operator'),
                                    icon: Icon(Icons.directions_bus_outlined),
                                  ),
                                ],
                                selected: {_role},
                                onSelectionChanged: _busy
                                    ? null
                                    : (v) => setState(() => _role = v.first),
                              ),
                              if (_role == 'operator') ...[
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _company,
                                  maxLength: 100,
                                  decoration: const InputDecoration(
                                    labelText: 'Operator / company name',
                                  ),
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Enter your operator name'
                                      : null,
                                ),
                              ],
                            ] else
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _reset,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: Text(
                                _busy
                                    ? 'Please wait…'
                                    : creating
                                    ? 'Create account'
                                    : 'Sign in',
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!widget.completeProfile)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                        _register = !_register;
                                        _error = null;
                                      }),
                                child: Text(
                                  creating
                                      ? 'Already have an account? Sign in'
                                      : 'New here? Create an account',
                                ),
                              ),
                            if (widget.completeProfile)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => FirebaseAuth.instance.signOut(),
                                child: const Text('Sign out'),
                              ),
                            const SizedBox(height: 32),
                            const Text(
                              'Commuters • Operators • Administrations',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
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
    );
  }
}
