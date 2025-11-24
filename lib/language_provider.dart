import 'package:flutter/material.dart';

/// รองรับ 2 ภาษา
enum AppLanguage { en, th }

/// เก็บข้อความ UI ทุกอัน (multi-language mapping)
class LangText {
  final String appTitle;

  final String profileEdit;
  final String profileHistory;
  final String profileLanguage;
  final String profileTheme;

  final String themeLight;
  final String themeDark;
  final String themeSheetTitle;

  final String languageSheetTitle;
  final String languageEnglish;
  final String languageThai;

  final String balanceLabel;
  final String errorLabel;
  final String notificationsComingSoon;

  final String signOut;

  const LangText({
    required this.appTitle,
    required this.profileEdit,
    required this.profileHistory,
    required this.profileLanguage,
    required this.profileTheme,
    required this.themeLight,
    required this.themeDark,
    required this.themeSheetTitle,
    required this.languageSheetTitle,
    required this.languageEnglish,
    required this.languageThai,
    required this.balanceLabel,
    required this.errorLabel,
    required this.notificationsComingSoon,
    required this.signOut,
  });
}

/// ภาษาอังกฤษ
const LangText enText = LangText(
  appTitle: "Tid Tung",

  profileEdit: "Edit Profile",
  profileHistory: "History",
  profileLanguage: "Language",
  profileTheme: "App Theme",

  themeLight: "Light",
  themeDark: "Dark",
  themeSheetTitle: "Select app theme",

  languageSheetTitle: "Select language",
  languageEnglish: "English",
  languageThai: "Thai",

  balanceLabel: "Balance",
  errorLabel: "Error",
  notificationsComingSoon: "Notifications coming soon",

  signOut: "Sign Out",
);

/// ภาษาไทย
const LangText thText = LangText(
  appTitle: "ติ๊ดตัง",

  profileEdit: "แก้ไขโปรไฟล์",
  profileHistory: "ประวัติการจ่ายเงิน",
  profileLanguage: "ภาษา",
  profileTheme: "ธีมของแอป",

  themeLight: "สว่าง",
  themeDark: "มืด",
  themeSheetTitle: "เลือกธีมของแอป",

  languageSheetTitle: "เลือกภาษา",
  languageEnglish: "อังกฤษ",
  languageThai: "ไทย",

  balanceLabel: "ยอดคงเหลือ",
  errorLabel: "ผิดพลาด",
  notificationsComingSoon: "ฟีเจอร์แจ้งเตือนจะมาเร็ว ๆ นี้",

  signOut: "ออกจากระบบ",
);


/// Provider หลักที่ใช้สลับภาษา
class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;  // ตั้งค่าเริ่มต้น

  AppLanguage get language => _language;

  LangText get text => _language == AppLanguage.th ? thText : enText;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners(); // ให้ UI รีเฟรชทั้งหมด
  }
}
