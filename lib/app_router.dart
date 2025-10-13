import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart'; // <-- if you have it

GoRouter buildRouter(BuildContext context) {
  final auth = context.read<AuthService>();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final authed = auth.signedIn;
      final loc = state.matchedLocation;
      // If not authenticated, block access to protected/profile
      if (!authed && (loc == '/protected' || loc == '/profile')) return '/login';
      // If authenticated and on login/register or unknown route, send to dashboard
      if (authed && (loc == '/login' || loc == '/register' || loc.startsWith('io.supabase.flutter'))) return '/protected';
      // If unknown route, send to login
      if (!authed && !(loc == '/login' || loc == '/register' || loc == '/protected' || loc == '/profile' || loc == '/protected-status')) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/protected', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
    errorBuilder: (_, __) => const LoginScreen(),
  );
}
