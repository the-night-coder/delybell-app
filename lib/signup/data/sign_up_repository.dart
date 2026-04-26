import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/static.dart';
import '../models/sign_up_type.dart';

class SignUpRepository {
  SignUpRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String countryDialCode,
    required String password,
    required String confirmPassword,
    required SignUpType signUpType,
  }) async {
    final uri = Uri.parse('${Static.baseUrl}initiate_registration');
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': '$countryDialCode$phoneNumber',
        'password': password,
        'confirm_password': confirmPassword,
        'user_type': signUpType.apiValue,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? 'Unable to create account';
    } catch (_) {
      return 'Unable to create account';
    }
  }
}
