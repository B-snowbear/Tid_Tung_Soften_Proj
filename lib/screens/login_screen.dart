import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _handleSignInGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await supa.Supabase.instance.client.auth.signInWithOAuth(
        supa.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'tidtung://auth-callback',
        authScreenLaunchMode: supa.LaunchMode.externalApplication,
      );
    } on supa.AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSignInEmail() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final auth = context.read<AuthService>();
      final tempToken = await auth.startLoginWithEmail(email, password);

      if (mounted) {
        context.push('/otp', extra: {
          'tempToken': tempToken,
          'email': email,
          'password': password,
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -------------------------------------------------------
                  // LOGO
                  // -------------------------------------------------------
                  Image.asset(
                    'assets/images/tidtung_logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // -------------------------------------------------------
                  // Title
                  // -------------------------------------------------------
                  Text(
                    'Tid Tung',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TTColors.cB7EDFF,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By Houma',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TTColors.cC9D7FF,
                          fontWeight: FontWeight.w500,
                        ),
                  ),

                  const SizedBox(height: 28),

                  // -------------------------------------------------------
                  // Email Field
                  // -------------------------------------------------------
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: TTColors.cB7EDFF,
                    decoration: _inputDecoration('Email'),
                  ),
                  const SizedBox(height: 12),

                  // -------------------------------------------------------
                  // Password Field
                  // -------------------------------------------------------
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: TTColors.cB7EDFF,
                    decoration: _inputDecoration('Password'),
                  ),
                  const SizedBox(height: 18),

                  // -------------------------------------------------------
                  // Email Login button
                  // -------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _handleSignInEmail,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign in with Email',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],

                  const SizedBox(height: 24),

                  // -------------------------------------------------------
                  // Google Sign-in
                  // -------------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _handleSignInGoogle,
                      style: FilledButton.styleFrom(
                        backgroundColor: TTColors.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: TTColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------
  // 🔧 Custom Input Decoration
  // ---------------------------------------------
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: TTColors.c0DBCF6, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
