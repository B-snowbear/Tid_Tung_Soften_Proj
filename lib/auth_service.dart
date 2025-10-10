import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  Future<void> signInMock() async {
    _signedIn = true;
    notifyListeners();
  }

  Future<void> registerMock({required String name, required String password}) async {
    _signedIn = true;
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    notifyListeners();
  }
}
