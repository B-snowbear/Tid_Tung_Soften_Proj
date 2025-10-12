import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  Session? _session;

  AuthService() {
    _session = Supabase.instance.client.auth.currentSession;
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _session = event.session;
      notifyListeners();
    });
  }

  bool get isLoggedIn => _session != null;
  // 🔧 alias so existing code using `signedIn` compiles
  bool get signedIn => isLoggedIn;

  User? get user => _session?.user;

  Future<void> signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.origin, // e.g., http://localhost:5173
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // 🔧 keep old mock API working by delegating to Google OAuth
  Future<void> signInMock() => signInWithGoogle();

  Future<void> registerMock({required String name, required String password}) =>
      signInWithGoogle();
}
