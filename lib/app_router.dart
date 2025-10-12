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
    initialLocation: '/signin',
    refreshListenable: auth,
    redirect: (ctx, state) {
      final loggedIn = auth.isLoggedIn;
      final atSignIn = state.matchedLocation == '/signin';

      // Handle root (/) explicitly
      if (state.matchedLocation == '/') {
        return loggedIn ? '/dashboard' : '/signin';
      }

      if (!loggedIn && !atSignIn) return '/signin';
      if (loggedIn && atSignIn)   return '/dashboard';
      return null;
    },
    routes: [
      // root mapping so "/" is valid
      GoRoute(
        path: '/',
        redirect: (ctx, state) => auth.isLoggedIn ? '/dashboard' : '/signin',
      ),
      GoRoute(path: '/signin',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),
    ],
  );
}
