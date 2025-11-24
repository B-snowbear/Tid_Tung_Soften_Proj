import 'package:flutter/material.dart';
import 'theme.dart';

/// โหมดธีมของแอป
enum AppThemeMode { dark, light }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  /// ใช้เช็กง่าย ๆ ว่าตอนนี้เป็นโหมดมืดไหม
  bool get isDark => _mode == AppThemeMode.dark;

  /// คืนค่าธีมปัจจุบันให้ MaterialApp ใช้
  ThemeData get theme {
    switch (_mode) {
      case AppThemeMode.light:
        return AppThemes.light();
      case AppThemeMode.dark:
      default:
        return AppThemes.dark();
    }
  }

  /// เซ็ตโหมดธีมแบบกำหนดเอง
  void setMode(AppThemeMode mode) {
    if (_mode == mode) return; // ถ้าเหมือนเดิมไม่ต้อง notify
    _mode = mode;
    notifyListeners();
  }

  /// toggle สลับ dark <-> light
  void toggle() {
    setMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
  }
}
