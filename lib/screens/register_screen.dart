import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;

  Future<void> _handleRegister() async {
    if (_loading) return;

    final name = _name.text.trim();
    final email = _email.text.trim();
    final pwd = _pwd.text;
    final confirm = _confirm.text;

    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

    String? error;
    if (name.isEmpty) {
      error = 'Please enter your name';
    } else if (email.isEmpty || !email.contains('@')) {
      error = 'Please enter a valid email';
    } else if (!passwordRegex.hasMatch(pwd)) {
      error =
          'Password must be ≥ 8 chars and include upper, lower, number, and special character.';
    } else if (pwd != confirm) {
      error = 'Passwords do not match';
    }

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _loading = true);
    try {
      final client = supa.Supabase.instance.client;

      final res = await client.auth.signUp(
        email: email,
        password: pwd,
        data: {
          'full_name': name,
        },
        emailRedirectTo: kIsWeb ? null : 'tidtung://auth-callback',
      );

      if (!mounted) return;

      if (res.session != null) {
        // signed in already
        context.go('/');
      } else {
        // need email confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account.'),
          ),
        );
        context.go('/login');
      }
    } on supa.AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
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
          child: Stack(
            children: [
              // back button
              Positioned(
                left: 12,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        // 🔹 ใช้โลโก้ตัวเดียวกับหน้า Login
                        Image.asset(
                          'assets/images/tidtung_logo.png',
                          width: 92,
                          height: 92,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(height: 92),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [TTColors.c0DBCF6, TTColors.cB7EDFF],
                          ).createShader(r),
                          child: Text(
                            'Create Profile',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _Field(
                          controller: _name,
                          hint: 'Enter Name',
                          icon: Icons.edit,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _email,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _pwd,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _obscure1,
                          onToggleObscure: () =>
                              setState(() => _obscure1 = !_obscure1),
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _confirm,
                          hint: 'Confirm Password',
                          icon: Icons.lock_outline,
                          obscure: _obscure2,
                          onToggleObscure: () =>
                              setState(() => _obscure2 = !_obscure2),
                        ),

                        const SizedBox(height: 28),
                        _GlowButton(
                          text: _loading ? 'Creating...' : 'Get Start',
                          onTap: _loading ? null : _handleRegister,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ widgets ------------------

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: TTColors.cB7EDFF,
      keyboardType:
          hint == 'Email' ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
        ),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.9),
                ),
                onPressed: onToggleObscure,
              ),
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
          borderSide:
              const BorderSide(color: TTColors.c0DBCF6, width: 1.4),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x330DBCF6),
          ),
        ],
      ),
      child: SizedBox(
        width: 220,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: TTColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
