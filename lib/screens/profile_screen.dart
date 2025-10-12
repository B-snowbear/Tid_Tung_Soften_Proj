import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final u = auth.user;

    final name  = (u?.userMetadata?['name'] as String?) ?? 'Houma';
    final email = u?.email ?? 'houma@gmail.com';
    final photo = u?.userMetadata?['picture'] as String?;
    const balanceText = '-12,000'; // mock for now

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
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
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications coming soon')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Avatar
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.25), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: photo == null
                          ? const Icon(Icons.account_circle, size: 110, color: Colors.white)
                          : Image.network(photo, width: 110, height: 110, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name / email
                Center(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TTColors.cB7EDFF,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),

                const SizedBox(height: 20),

                // Balance mock
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Balance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      balanceText,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFFF6E40),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Menu
                _Menu(label: 'Edit Profile', onTap: () {}),
                const Divider(color: Colors.white24, height: 24),
                _Menu(label: 'History', onTap: () {}),
                const Divider(color: Colors.white24, height: 24),
                _Menu(label: 'Language', onTap: () {}),
                const Divider(color: Colors.white24, height: 24),
                _Menu(label: 'App Theme', onTap: () {}),

                const Spacer(),

                // Sign out
                Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: Offset(0, 8),
                          color: Color(0x330DBCF6),
                        )
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
                          context.go('/signin'); // make sure this route exists in GoRouter
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
