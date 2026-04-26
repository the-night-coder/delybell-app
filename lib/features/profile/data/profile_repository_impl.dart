import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../../../login/models/login_response.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({http.Client? client, this.baseUrl = Static.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<LoginResponse> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/update_profile');
    _logRequest('PUT', uri, payload);
    final response = await _client.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );
    _logResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    return LoginResponse(
      status: decoded['status'] as bool? ?? true,
      message: decoded['message']?.toString() ?? 'Profile updated successfully',
      token: decoded['token']?.toString().isNotEmpty == true
          ? decoded['token'].toString()
          : token,
      user: LoginUser.fromJson(data),
    );
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final msg = decoded['message']?.toString();
      return ErrorUtils.friendly(msg ?? 'Failed to update profile',
          fallback: 'Failed to update profile');
    } catch (_) {
      return ErrorUtils.friendly(body, fallback: 'Failed to update profile');
    }
  }

  void _logRequest(String method, Uri uri, Object? body) {
    // ignore: avoid_print
    print('[ProfileRepository] $method $uri');
    if (body != null) {
      // ignore: avoid_print
      print('[ProfileRepository] payload: $body');
    }
  }

  void _logResponse(http.Response response) {
    // ignore: avoid_print
    final preview = response.body.length > 400
        ? '${response.body.substring(0, 400)}...'
        : response.body;
    print('[ProfileRepository] ${response.statusCode} ${response.request?.url}\n$preview');
  }
}
