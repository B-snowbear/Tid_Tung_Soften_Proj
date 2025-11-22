import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _sendReset() async {
    if (_loading) return;
    final email = _email.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }

    setState(() => _loading = true);
    try {
      final client = supa.Supabase.instance.client;
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'tidtung://password-reset', // you can adapt this
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email for a reset link.')),
      );
    } on supa.AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple UI: one text field + button
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendReset,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}
