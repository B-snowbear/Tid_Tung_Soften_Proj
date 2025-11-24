import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TTColors {
  static const c0DBCF6 = Color(0xFF0DBCF6); // cyan accent
  static const c1877F2 = Color(0xFF1877F2); // primary blue
  static const cB7EDFF = Color(0xFFB7EDFF); // light cyan
  static const c3557BC = Color(0xFF3557BC); // deep blue
  static const cC9D7FF = Color(0xFFC9D7FF); // lavender text hint
  static const c4147D5 = Color(0xFF4147D5); // indigo

  static const bgStart = c3557BC;
  static const bgEnd   = c4147D5;
  static const primary = c1877F2;
  static const accent  = c0DBCF6;

  static const textOnDark = Colors.white;
  static const surface = Colors.white;
}

/// ใช้ชุดนี้ใน ThemeProvider
class AppThemes {
  /// DARK THEME (เหมือนธีมเดิมของโปรเจกต์)
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: TTColors.primary,
        secondary: TTColors.accent,
        surface: TTColors.surface,
        onSurface: TTColors.textOnDark,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TTColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: TTColors.cC9D7FF),
      ),
    );
  }

  /// LIGHT THEME ง่าย ๆ (พื้นขาว ปุ่มน้ำเงิน)
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      colorScheme: base.colorScheme.copyWith(
        primary: TTColors.primary,
        secondary: TTColors.accent,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TTColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: TTColors.c1877F2),
      ),
    );
  }
}

/// เผื่อโค้ดเก่าไหนยังเรียกอยู่ จะใช้ Dark theme เป็นค่า default
ThemeData buildAppTheme() => AppThemes.dark();
