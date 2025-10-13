import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Replace 'profiles' with your actual table name for user profiles
const String userTable = 'profiles';

class AuthService extends ChangeNotifier {

  Future<void> register(String username, String password) async {
    // For registration, we need to create a user with email and password, and store username in profiles table
    final email = '$username@tidtung.com'; // or prompt for email if needed
    final response = await _supabase.auth.signUp(email: email, password: password);
    if (response.user == null) {
      throw Exception('Registration failed');
    }
    // Insert username into profiles table
    await _supabase.from(userTable).upsert({
      'id': response.user!.id,
      'username': username,
      'email': email,
    });
    _signedIn = true;
    notifyListeners();
  }
  User? get user => _supabase.auth.currentUser;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  Future<String?> getEmailForUsername(String username) async {
    final response = await _supabase
        .from(userTable)
        .select('email')
        .eq('username', username)
        .single();
    return response['email'] as String?;
  }

  Future<void> signInWithUsername(String username, String password) async {
    final email = await getEmailForUsername(username);
    if (email == null) throw Exception('Username not found');
    await signInWithEmail(email, password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    if (response.session == null || response.user == null) {
      throw Exception('Login failed: Invalid email or password');
    }
    _signedIn = true;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
      queryParams: {'prompt': 'select_account'},
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _signedIn = false;
    notifyListeners();
  }
}
