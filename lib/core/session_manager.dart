import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../login/models/login_response.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager _instance = SessionManager._();

  factory SessionManager() => _instance;

  static const _loginKey = 'login_response';

  Future<void> saveLogin(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _loginKey,
      jsonEncode(response.toJson()),
    );
  }

  Future<LoginResponse?> loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_loginKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return LoginResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
  }
}
