import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/protected_screen.dart'; // optional: for status screenshot
import 'screens/profile_screen.dart';   // ⬅️ NEW

GoRouter buildRouter(BuildContext rootContext) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: rootContext.read<AuthService>(),
    redirect: (context, state) {
      final authed = rootContext.read<AuthService>().signedIn;
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
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/protected', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/protected-status', builder: (_, __) => const ProtectedScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()), // ⬅️ NEW
    ],
    errorBuilder: (_, __) => const LoginScreen(),
  );
}
