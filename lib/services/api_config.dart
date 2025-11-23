import 'dart:io';
import 'package:flutter/foundation.dart';

// API configuration based on platform
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:4000";
    }

    if (Platform.isAndroid) {
      return "http://10.0.2.2:4000";
    }

    return "http://localhost:4000";
  }
}
