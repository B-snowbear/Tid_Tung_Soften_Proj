import 'dart:convert';
import 'package:flutter/foundation.dart'; // ChangeNotifier + kIsWeb
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _signedIn = false;
  bool get signedIn => _signedIn;

  // Platform-aware backend base URL for 2FA endpoints
  String get _authBase {
    return kIsWeb
        ? 'http://localhost:4000/api/auth'   // Web / Chrome
        : 'http://10.0.2.2:4000/api/auth';   // Android emulator → host
  }

  AuthService() {
    _signedIn = _supabase.auth.currentSession != null;

    _supabase.auth.onAuthStateChange.listen((data) {
      _signedIn = data.session != null;
      notifyListeners();
    });
  }

  // -----------------------------
  // STEP 1: Start Email Login (Ask backend to send OTP)
  // -----------------------------
  Future<String> startLoginWithEmail(String email, String password) async {
    final url = Uri.parse('$_authBase/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'Login failed');
      } catch (_) {
        throw Exception('Login failed (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tempToken = data['tempToken'] as String?;
    if (tempToken == null) {
      throw Exception('Missing tempToken from server');
    }
    return tempToken;
  }

  // -----------------------------
  // STEP 2: Submit OTP
  // -----------------------------
  Future<void> verifyOtp(String tempToken, String otp) async {
    final url = Uri.parse('$_authBase/verify-otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tempToken': tempToken,
        'otp': otp,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'OTP failed');
      } catch (_) {
        throw Exception('OTP failed (${response.statusCode})');
      }
    }

    // If backend also creates a Supabase session,
    // the auth listener will keep _signedIn in sync.
    _signedIn = true;
    notifyListeners();
  }

  // -----------------------------
  // FR-3: Password Reset Request
  // -----------------------------
  Future<void> requestPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'tidtung://password-reset',
    );
  }

  // -----------------------------
  // Google Login (unchanged)
  // -----------------------------
  Future<void> signInWithGoogle() async {
    try {
      final redirect =
          kIsWeb ? Uri.base.origin : 'io.supabase.flutter://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        queryParams: {
          'prompt': 'select_account',
          'access_type': 'offline',
        },
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // -----------------------------
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _signedIn = false;
    notifyListeners();
  }
}
