import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/static.dart';
import '../models/address_lookup.dart';

class DomesticOrderRepository {
  DomesticOrderRepository({
    http.Client? client,
    this.baseUrl = Static.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<BlockInfo>> fetchBlocks({
    required String token,
    String search = '',
  }) async {
    final uri = Uri.parse('${baseUrl}user/master/block/list?search=$search');
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data.map((item) => BlockInfo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<RoadInfo>> fetchRoads({
    required String token,
    required int blockId,
    String search = '',
  }) async {
    final uri =
        Uri.parse('${baseUrl}user/master/road/list?block_id=$blockId&search=$search');
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data.map((item) => RoadInfo.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<BuildingInfo>> fetchBuildings({
    required String token,
    required int blockId,
    required int roadId,
    String search = '',
  }) async {
    final uri = Uri.parse(
        '${baseUrl}user/master/building/list?block_id=$blockId&road_id=$roadId&search=$search');
    final response = await _client.get(uri, headers: _headers(token));
    _throwIfError(response);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => BuildingInfo.fromJson(item as Map<String, dynamic>))
        .toList();
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
      throw Exception(decoded['message']?.toString() ?? 'Request failed');
    } catch (_) {
      throw Exception('Request failed');
    }
  }
}
