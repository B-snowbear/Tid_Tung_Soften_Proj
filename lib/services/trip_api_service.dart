import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class TripApiService {
  final _sb = Supabase.instance.client;

  String get _base {
    // Web uses localhost; Android emulator uses 10.0.2.2
    return kIsWeb
        ? 'http://localhost:4000/api/trips'
        : 'http://10.0.2.2:4000/api/trips';
  }

  Future<List<Map<String, dynamic>>> list() async {
    final token = _sb.auth.currentSession?.accessToken;
    final r = await http.get(Uri.parse(_base),
        headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode != 200) {
      throw Exception('GET /api/trips failed: ${r.body}');
    }
    final data = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    return data;
  }

  Future<void> create({
    required String name,
    String? destination,
    required DateTime start,
    required DateTime end,
    String? description,
  }) async {
    final token = _sb.auth.currentSession?.accessToken;
    final body = jsonEncode({
      'name': name,
      'destination': destination,
      'start_date': start.toIso8601String().substring(0, 10),
      'end_date': end.toIso8601String().substring(0, 10),
      'description': description,
    });
    final r = await http.post(
      Uri.parse(_base),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: body,
    );
    if (r.statusCode != 201) {
      throw Exception('POST /api/trips failed: ${r.body}');
    }
  }
}
