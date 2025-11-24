import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'api_config.dart';

class NotificationApiService extends ChangeNotifier {
  final _sb = Supabase.instance.client;

  List<AppNotification> notifications = [];
  // bool loading = false;

  Future<String?> getAccessToken() async {
    final session = _sb.auth.currentSession;
    return session?.accessToken;
  }

  Future<void> fetchNotifications() async {
    // loading = true;
    notifyListeners();

    final token = await getAccessToken();
    if (token == null) {
      // loading = false;
      notifyListeners();
      return;
    }

    final api = ApiConfig.baseUrl;

    // GET /api/notifications
    final res = await http.get(
      Uri.parse("$api/api/notifications"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List raw = jsonDecode(res.body);
      notifications = raw.map((e) => AppNotification.fromJson(e)).toList();
    }

    // loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final token = await getAccessToken();
    if (token == null) return;

    final api = ApiConfig.baseUrl;

    // PATCH /api/notifications/read/:id
    await http.patch(
      Uri.parse("$api/api/notifications/read/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    await fetchNotifications(); // refresh
  }

  Future<void> markAllRead() async {
    final token = await getAccessToken();
    if (token == null) return;

    final api = ApiConfig.baseUrl;

    // PATCH /api/notifications/read-all
    await http.patch(
      Uri.parse("$api/api/notifications/read-all"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    await fetchNotifications(); // refresh
  }

  Future<void> deleteNotification(String id) async {
    final token = await getAccessToken();
    if (token == null) return;

    final api = ApiConfig.baseUrl;

    // DELETE /api/notifications/:id
    await http.delete(
      Uri.parse("$api/api/notifications/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    await fetchNotifications();
  }

  Future<void> clearAll() async {
    final token = await getAccessToken();
    if (token == null) return;

    final api = ApiConfig.baseUrl;

    /// DELETE /api/notifications (clear all)
    await http.delete(
      Uri.parse("$api/api/notifications"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    await fetchNotifications();
  }
}
