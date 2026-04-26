import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/static.dart';
import '../models/login_response.dart';
import '../models/login_type.dart';

class LoginRepository {
  LoginRepository({http.Client? client, this.baseUrl = Static.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<LoginResponse> login({
    required LoginType loginType,
    required String email,
    required String password,
  }) async {
    final endpoint = switch (loginType) {
      LoginType.user => 'customer/login',
      LoginType.corporate => 'customer/corporate/login',
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _parseError(response.body);
      throw Exception(message);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponse.fromJson(decoded);
  }

  Future<String> forgotPassword({required String email}) async {
    final uri = Uri.parse('${baseUrl}customer/forgot_password');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _parseError(response.body);
      throw Exception(message);
    }
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      final message = decoded['message']?.toString();
      return message ??
          'Password reset instructions have been sent to your email';
    } catch (_) {
      return 'Password reset instructions have been sent to your email';
    }
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? 'Unable to sign in';
    } catch (_) {
      return 'Unable to sign in';
    }
  }
}
