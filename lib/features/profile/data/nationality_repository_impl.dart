import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../domain/entities/nationality.dart';
import '../domain/repositories/nationality_repository.dart';

class NationalityRepositoryImpl implements NationalityRepository {
  NationalityRepositoryImpl({http.Client? client, this.baseUrl = Static.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<List<Nationality>> fetchNationalities({
    required String token,
    String search = '',
  }) async {
    final uri = Uri.parse('${baseUrl}user/master/nationality/list')
        .replace(queryParameters: {'search': search});
    _logRequest(uri);

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _logResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => Nationality.fromJson(item as Map<String, dynamic>? ?? const {}))
        .toList();
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>? ?? {};
      final msg = decoded['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        return ErrorUtils.friendly(msg, fallback: 'Unable to load nationalities');
      }
    } catch (_) {
      // ignore parsing error
    }
    return ErrorUtils.friendly(body, fallback: 'Unable to load nationalities');
  }

  void _logRequest(Uri uri) {
    debugPrint('[NationalityApi] GET $uri');
  }

  void _logResponse(http.Response response) {
    debugPrint(
      '[NationalityApi] RESPONSE ${response.statusCode} ${response.request?.url}\n${response.body}',
    );
  }
}
