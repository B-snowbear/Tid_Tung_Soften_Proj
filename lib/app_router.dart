import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';  // 👈 NEW
import 'auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/protected_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/otp_screen.dart';

// 👇 NEW: a global navigator key we can use from main.dart
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();


GoRouter buildRouter(BuildContext rootContext) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: rootContext.read<AuthService>(),
    redirect: (context, state) {
      final authed = rootContext.read<AuthService>().signedIn;
      final loc = state.matchedLocation;

      // If not logged in and trying to access protected pages → send to /login
      if (!authed && (loc == '/protected' || loc == '/profile')) return '/login';

      // If logged in and trying to access login/register or OAuth callback → send to /protected
      if (authed &&
          (loc == '/login' ||
          loc == '/register' ||
          loc.startsWith('io.supabase.flutter'))) return '/protected';

      // If NOT logged in, only allow some public routes:
      if (!authed &&
        !(loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/otp' ||                 // 👈 allow OTP screen
          loc == '/protected-status')) {
      return '/login';
    }


      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/protected', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/protected-status', builder: (_, __) => const ProtectedScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return OtpScreen(
            tempToken: data['tempToken'],
            email: data['email'],
            password: data['password'],
          );
        },
      ),


      // ⬇️ NEW Trip Detail route
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Trip';
          return TripDetailScreen(tripId: id, tripName: name);
        },
      ),
    ],
    errorBuilder: (_, __) => const LoginScreen(),
  );
}
