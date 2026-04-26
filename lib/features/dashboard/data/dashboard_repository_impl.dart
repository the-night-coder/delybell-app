import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../../../dashboard/models/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    http.Client? client,
    this.baseUrl = Static.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  static const _cacheKey = 'dashboard_summary_cache';

  @override
  Future<DashboardSummary> fetchDashboard({required String token}) async {
    final uri = Uri.parse('${baseUrl}customer/dashboard');
    _logRequest('GET', uri);
    final response = await _client.get(
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

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    final summary = DashboardSummary.fromJson(data);
    await _cacheSummary(summary);
    return summary;
  }

  @override
  Future<DashboardSummary?> loadCachedSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return DashboardSummary.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheSummary(DashboardSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(summary.toJson()));
    } catch (_) {}
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final msg = decoded['message']?.toString();
      return ErrorUtils.friendly(
        msg ?? 'Unable to load dashboard',
        fallback: 'Unable to load dashboard',
      );
    } catch (_) {
      return ErrorUtils.friendly(body, fallback: 'Unable to load dashboard');
    }
  }

  void _logRequest(String method, Uri uri) {
    // ignore: avoid_print
    print('[DashboardRepository] $method $uri');
  }

  void _logResponse(http.Response response) {
    // ignore: avoid_print
    final preview = response.body.length > 400
        ? '${response.body.substring(0, 400)}...'
        : response.body;
    print('[DashboardRepository] ${response.statusCode} ${response.request?.url}\n$preview');
  }
}
