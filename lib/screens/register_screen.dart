import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final pwd = TextEditingController();
  final confirm = TextEditingController();
  bool obscure1 = true, obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [TTColors.bgStart, TTColors.bgEnd],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 12, top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/tid_tung_logo.png',
                          width: 92, height: 92, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(height: 92),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [TTColors.c0DBCF6, TTColors.cB7EDFF],
                          ).createShader(r),
                          child: Text('Create Profile',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white, fontWeight: FontWeight.w800,
                                  )),
                        ),
                        const SizedBox(height: 24),
                        _Field(controller: name, hint: 'Enter Name', icon: Icons.edit),
                        const SizedBox(height: 12),
                        _Field(
                          controller: pwd, hint: 'Password', icon: Icons.lock_outline,
                          obscure: obscure1, onToggleObscure: () => setState(() => obscure1 = !obscure1),
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: confirm, hint: 'Confirm Password', icon: Icons.lock_outline,
                          obscure: obscure2, onToggleObscure: () => setState(() => obscure2 = !obscure2),
                        ),
                        const SizedBox(height: 28),
                        _GlowButton(
                          text: 'Get Start',
                          onTap: () async {
                            final n = name.text.trim();
                            if (n.isEmpty || pwd.text.length < 6 || pwd.text != confirm.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter name and matching passwords (min 6 chars).')),
                              );
                              return;
                            }
                            await context.read<AuthService>().registerMock(name: n, password: pwd.text);
                            if (!mounted) return;
                            context.go('/protected');
                          },
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.9)),
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
          borderSide: const BorderSide(color: TTColors.c0DBCF6, width: 1.4),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(blurRadius: 18, offset: Offset(0, 8), color: Color(0x330DBCF6))],
      ),
      child: SizedBox(
        width: 220,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: TTColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
