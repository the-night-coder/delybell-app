import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../domain/entities/address_entity.dart';
import '../domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({http.Client? client, this.baseUrl = Static.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<List<AddressEntity>> fetchAddresses({required String token}) async {
    final uri = Uri.parse('${baseUrl}customer/addresses/list')
        .replace(queryParameters: const {'order_by': 'is_primary'});
    _logRequest('GET', uri);
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
        .map((item) => AddressEntity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateAddress({
    required String token,
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}addresses/update/$id');
    _logRequest('PUT', uri, body: payload);
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
  }

  @override
  Future<void> createAddress({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}addresses/create');
    _logRequest('POST', uri, body: payload);
    final response = await _client.post(
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
  }

  @override
  Future<void> deleteAddress({required String token, required int id}) async {
    final uri = Uri.parse('${baseUrl}addresses/delete/$id');
    _logRequest('DELETE', uri);
    final response = await _client.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _logResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }

  @override
  Future<void> markPrimary({required String token, required int id}) async {
    final uri = Uri.parse('${baseUrl}addresses/update/primary/$id');
    _logRequest('PUT', uri);
    final response = await _client.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    _logResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_parseError(response.body));
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>? ?? {};
      final msg = json['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        return ErrorUtils.friendly(msg, fallback: 'Something went wrong. Please try again.');
      }
    } catch (_) {
      // ignore
    }
    return ErrorUtils.friendly(body, fallback: 'Something went wrong. Please try again.');
  }

  void _logRequest(String method, Uri uri, {Map<String, dynamic>? body}) {
    debugPrint('[AddressApi] $method $uri');
    if (body != null) {
      debugPrint(jsonEncode(body));
    }
  }

  void _logResponse(http.Response response) {
    debugPrint(
      '[AddressApi] RESPONSE ${response.statusCode} ${response.request?.url}\n${response.body}',
    );
  }
}
