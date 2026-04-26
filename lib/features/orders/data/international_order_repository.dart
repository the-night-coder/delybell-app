import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../domain/entities/international_models.dart';

class InternationalOrderRepository {
  InternationalOrderRepository({http.Client? client, this.baseUrl = Static.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<CountryInfo>> fetchCountries({
    required String token,
    String search = '',
  }) async {
    final uri = Uri.parse('${baseUrl}user/master/country/list')
        .replace(queryParameters: {'search': search});
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CountryInfo.fromJson)
        .toList();
  }

  Future<List<CityInfo>> fetchCities({
    required String token,
    required int countryId,
    String search = '',
  }) async {
    final uri = Uri.parse('${baseUrl}customer/international/cities/list')
        .replace(queryParameters: {
          'country_id': countryId.toString(),
          'search': search,
        });
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CityInfo.fromJson)
        .toList();
  }

  Future<List<InternationalRateOption>> fetchRates({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/shipping/rates/all');
    final response = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    _throwIfError(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    final rates = data['rates'] as List<dynamic>? ?? const [];
    return rates
        .whereType<Map<String, dynamic>>()
        .map(InternationalRateOption.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> initiateDraft({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/international/draft/initiate');
    final response = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    _throwIfError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchDraftDetails({
    required String token,
    required int draftId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/international/draft/details/$draftId');
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'] as Map<String, dynamic>? ?? const {};
  }

  Future<void> approveAndPlace({
    required String token,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/international/order/place');
    final response = await _client.post(uri, headers: _headers(token));
    _throwIfError(response);
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = decoded['message']?.toString();
      throw Exception(
        ErrorUtils.friendly(msg ?? response.body, fallback: 'Request failed'),
      );
    } catch (_) {
      throw Exception(ErrorUtils.friendly(response.body, fallback: 'Request failed'));
    }
  }
}
