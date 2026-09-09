import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  static const String _cachedTicketsKey = 'fsm_cached_tickets';
  static const String _authUserDataKey = 'fsm_auth_user_data';

  /// Save tickets list to local cache
  static Future<void> saveTickets(List<Map<String, dynamic>> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedTicketsKey, jsonEncode(tickets));
  }

  /// Retrieve cached tickets
  static Future<List<Map<String, dynamic>>> getCachedTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cachedTicketsKey);
    if (data == null || data.isEmpty) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Store user session
  static Future<void> saveUserSession(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString(_authUserDataKey, jsonEncode(user));
  }

  /// Retrieve token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Retrieve saved user
  static Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authUserDataKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove(_authUserDataKey);
  }

  /// Clear offline tickets cache
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTicketsKey);
  }
}
