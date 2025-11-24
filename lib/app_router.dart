import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/protected_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'ui/billing/my_paid_history_page.dart';
import 'ui/billing/trip_report_page.dart'; // 👈 เดี๋ยวเราจะทำไฟล์หน้านี้

/// 👇 global navigator key (ใช้ใน main.dart)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(BuildContext rootContext) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: rootContext.read<AuthService>(),

    redirect: (context, state) {
      final authed = rootContext.read<AuthService>().signedIn;
      final loc = state.matchedLocation;

      // ---------- ถ้ายังไม่ล็อกอิน ----------
      // กันทุกเพจที่ต้องล็อกอิน: protected, profile, trip*, my-history
      if (!authed &&
          (loc == '/protected' ||
           loc == '/profile' ||
           loc == '/my-history' ||
           loc.startsWith('/trip'))) {
        return '/login';
      }

      // ---------- ถ้าล็อกอินแล้ว ----------
      // ไม่ให้กลับไปหน้า login / register / OAuth callback
      if (authed &&
          (loc == '/login' ||
           loc == '/register' ||
           loc.startsWith('io.supabase.flutter'))) {
        return '/protected';
      }

      // public routes ที่อนุญาตตอนยังไม่ล็อกอิน
      if (!authed &&
          !(loc == '/login' ||
            loc == '/register' ||
            loc == '/forgot-password' ||
            loc == '/reset-password' ||
            loc == '/otp' ||
            loc == '/protected-status')) {
        return '/login';
      }

      return null; // ไม่ redirect
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/protected',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/protected-status',
        builder: (_, __) => const ProtectedScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/my-history',
        builder: (_, __) => const MyPaidHistoryPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/trip/:id/report',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Trip report';
          return TripReportPage(tripId: id, tripName: name);
        },
      ),
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

      // ---------- Trip Detail ----------
      GoRoute(
        path: '/trip/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Trip';
          return TripDetailScreen(tripId: id, tripName: name);
        },
      ),

      // ---------- Trip Report (Reports & Charts) ----------
      GoRoute(
        path: '/trip/:id/report',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.extra as String? ?? 'Trip';
          return TripReportPage(tripId: id, tripName: name);
        },
      ),
    ],

    errorBuilder: (_, __) => const LoginScreen(),
  );
}
