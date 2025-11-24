// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_service.dart';
import '../theme.dart';
import '../theme_provider.dart';
import '../services/expense_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<double> _balanceFuture;

  String? _displayName;
  String? _email;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _reloadUserInfo();
    _balanceFuture = ExpenseService.getMyTotalBalance();
  }

  void _reloadUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final meta = user?.userMetadata ?? const {};

    _email = email;
    _displayName = (meta['name'] as String?) ?? email;
    _avatarUrl = meta['avatar_url'] as String?;
  }

  void _reloadBalance() {
    setState(() {
      _balanceFuture = ExpenseService.getMyTotalBalance();
    });
  }

  Future<void> _openEditProfile() async {
    final updated = await context.push<bool>('/profile/edit');
    if (updated == true) {
      setState(() {
        _reloadUserInfo();
      });
      _reloadBalance();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _openThemeChooser() async {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Select app theme',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Light'),
                trailing: !isDark
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  themeProvider.setMode(AppThemeMode.light);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark'),
                trailing: isDark
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  themeProvider.setMode(AppThemeMode.dark);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    final name = _displayName ?? '';
    final email = _email ?? '';

    // ใช้สีจาก theme ปัจจุบัน ทำให้ gradient เปลี่ยนตาม theme
    final scheme = Theme.of(context).colorScheme;
    final bgColors = [
      scheme.primary.withOpacity(isDark ? 0.95 : 0.80),
      scheme.secondary.withOpacity(isDark ? 0.95 : 0.80),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Top row ----------
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _showSnack('Notifications coming soon');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ---------- Avatar ----------
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(.25),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _avatarUrl!,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.account_circle,
                            size: 110,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---------- Name / Email ----------
                Center(
                  child: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    email,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: TTColors.cB7EDFF,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Balance ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Balance',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<double>(
                      future: _balanceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.error_outline,
                                  color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Error',
                                style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }

                        final value = snapshot.data ?? 0;
                        final isPositive = value >= 0;
                        final text = value.toStringAsFixed(0);

                        return Text(
                          text,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: isPositive
                                    ? const Color(0xFF00E676) // เขียว
                                    : const Color(0xFFFF6E40), // แดง
                                fontWeight: FontWeight.w800,
                              ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ---------- Menu ----------
                _Menu(label: 'Edit Profile', onTap: _openEditProfile),
                const Divider(color: Colors.white24, height: 24),
                _Menu(
                  label: 'History',
                  onTap: () => context.push('/my-history'),
                ),
                const Divider(color: Colors.white24, height: 24),
                _Menu(
                  label: 'Language',
                  onTap: () => _showSnack('Language: coming soon'),
                ),
                const Divider(color: Colors.white24, height: 24),
                _Menu(
                  label: 'App Theme (${isDark ? 'Dark' : 'Light'})',
                  onTap: _openThemeChooser,
                ),

                const Spacer(),

                // ---------- Sign out ----------
                Center(
                  child: Container(
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
                        style: FilledButton.styleFrom(
                          backgroundColor: TTColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          await context.read<AuthService>().signOut();
                          context.go('/login');
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
