// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'theme.dart';

enum AppThemeMode { dark, light }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark; // ค่าเริ่มต้น

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  ThemeData get theme {
    switch (_mode) {
      case AppThemeMode.light:
        return AppThemes.light();
      case AppThemeMode.dark:
      default:
        return AppThemes.dark();
    }
  }

  void toggleTheme() {
    _mode =
        _mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    notifyListeners();
  }

  /// ใช้เปลี่ยนโหมดแบบกำหนดค่าได้ตรง ๆ
  void setMode(AppThemeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
  }
}
