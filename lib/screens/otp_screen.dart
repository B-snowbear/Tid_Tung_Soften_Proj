import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa; // 👈 ADD THIS

import '../auth_service.dart';
import '../theme.dart';

class OtpScreen extends StatefulWidget {
  final String tempToken;
  final String email;
  final String password;

  const OtpScreen({
    super.key,
    required this.tempToken,
    required this.email,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submitOtp() async {
    if (_loading) return;
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _error = 'OTP must be 6 digits.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1️⃣ Verify OTP with backend
      await context.read<AuthService>().verifyOtp(widget.tempToken, otp);

      // 2️⃣ Sign in to Supabase AFTER OTP verification
      final sb = supa.Supabase.instance.client;
      await sb.auth.signInWithPassword(
        email: widget.email,
        password: widget.password,
      );

      // 3️⃣ Navigate to protected page
      if (mounted) context.go('/protected');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose(); // 👈 nice clean-up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Enter OTP', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'We have sent a 6-digit code to your email.\nEnter it below to finish signing in.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '123456',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.18),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                        borderSide:
                            BorderSide(color: TTColors.c0DBCF6, width: 1.4),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    cursorColor: TTColors.cB7EDFF,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitOtp,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify OTP'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
