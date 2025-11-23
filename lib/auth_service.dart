import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.session == null || response.user == null) {
        throw Exception('Login failed: Invalid email or password');
      }
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }
  Future<void> registerMock({required String name, required String password}) async {
    // Simulate registration logic (no-op for mock)
    await Future.delayed(const Duration(milliseconds: 500));
  }
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  AuthService() {
    // Check initial auth state
    _signedIn = _supabase.auth.currentSession != null;
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      _signedIn = session != null;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      // On web, redirect back to the tab you’re currently on (e.g. http://localhost:5xxxx)
      // On mobile/desktop apps, keep the deep link (Supabase default sample).
      final redirect = kIsWeb
          ? Uri.base.origin // e.g. http://localhost:52731
          : 'io.supabase.flutter://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        // optional but helpful:
        queryParams: {
          'prompt': 'select_account',   // or 'consent'
          'access_type': 'offline',     // get refresh_token on web
        },
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
    }
  }


  Future<void> signOut() async {
  await _supabase.auth.signOut();
  debugPrint('After signOut, session: ${_supabase.auth.currentSession}');
  _signedIn = false;
  notifyListeners();
  }

  // The old mock methods are no longer needed
  // Future<void> signInMock() async { ... }
  // Future<void> registerMock({required String name, required String password}) async { ... }
}

