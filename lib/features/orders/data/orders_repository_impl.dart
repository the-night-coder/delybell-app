import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/error_utils.dart';
import '../../../core/static.dart';
import '../../../dashboard/models/order_summary.dart';
import '../../../dashboard/models/order_tracking.dart';
import '../domain/entities/draft_place_preview.dart';
import '../domain/entities/orders_page.dart';
import '../domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({http.Client? client, this.baseUrl = Static.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<OrdersPage> fetchOrders({
    required String token,
    int page = 1,
    int limit = 10,
    String search = '',
    String? endpoint,
    String? filterByDeliveryStatus,
  }) async {
    final path = endpoint ?? 'customer/order/list';
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (filterByDeliveryStatus != null && filterByDeliveryStatus.isNotEmpty) {
      query['filter_by_delivery_status'] = filterByDeliveryStatus;
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
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
    final data = decoded['data'];

    if (data is List) {
      final orders = data
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
      return OrdersPage(orders: orders, currentPage: 1, lastPage: 1);
    }

    final dataMap = data as Map<String, dynamic>? ?? const {};
    final meta = dataMap['meta'] as Map<String, dynamic>? ?? const {};
    final list = dataMap['data'] as List<dynamic>? ?? const [];

    final orders = list
        .whereType<Map<String, dynamic>>()
        .map(OrderSummary.fromJson)
        .toList();

    return OrdersPage(
      orders: orders,
      currentPage: meta['currentPage'] is int
          ? meta['currentPage'] as int
          : int.tryParse(meta['currentPage']?.toString() ?? '') ?? page,
      lastPage: meta['lastPage'] is int
          ? meta['lastPage'] as int
          : int.tryParse(meta['lastPage']?.toString() ?? '') ?? page,
    );
  }

  @override
  Future<OrderTracking> fetchOrderTracking({
    required String token,
    required int orderId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/tracking/$orderId');
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
    return OrderTracking.fromJson(data);
  }

  @override
  Future<Map<String, dynamic>> initiateDraftOrder({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/initiate');
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

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  @override
  Future<Map<String, dynamic>> previewDraftOrder({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/preview');
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

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded;
  }

  @override
  Future<void> acceptDraftOrder({
    required String token,
    required int draftOrderId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/accept');
    final payload = {'draft_order_id': draftOrderId};
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
  Future<void> deleteDraftOrder({
    required String token,
    required int draftOrderId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/delete/$draftOrderId');
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
  Future<void> clearDraftOrders({
    required String token,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/clear');
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
  Future<void> placeDraftOrders({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/place');
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
  Future<DraftPlacePreview> previewPlaceDraftOrders({
    required String token,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/place/preview');
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
    final decoded = jsonDecode(response.body) as Map<String, dynamic>? ?? const {};
    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    return DraftPlacePreview.fromJson(data);
  }

  @override
  Future<void> markDraftFuturePickup({
    required String token,
    required int draftOrderId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/future_pickup/$draftOrderId');
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

  @override
  Future<void> cancelOrder({
    required String token,
    required int orderId,
    String? reason,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/cancel');
    final payload = <String, dynamic>{'order_id': orderId};
    final trimmedReason = reason?.trim() ?? '';
    if (trimmedReason.isNotEmpty) {
      payload['reason'] = trimmedReason;
    }
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
  Future<Map<String, dynamic>> fetchDraftDetails({
    required String token,
    required int draftOrderId,
  }) async {
    final uri = Uri.parse('${baseUrl}customer/order/draft/details/$draftOrderId');
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
    final decoded = jsonDecode(response.body) as Map<String, dynamic>? ?? const {};
    return decoded['data'] as Map<String, dynamic>? ?? const {};
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final msg = decoded['message']?.toString();
      return ErrorUtils.friendly(msg ?? 'Unable to load orders',
          fallback: 'Unable to load orders');
    } catch (_) {
      return ErrorUtils.friendly(body, fallback: 'Unable to load orders');
    }
  }

  void _logRequest(String method, Uri uri, {Object? body}) {
    // ignore: avoid_print
    print('[OrdersRepository] $method $uri');
    if (body != null) {
      // ignore: avoid_print
      print('[OrdersRepository] payload: $body');
    }
  }

  void _logResponse(http.Response response) {
    // ignore: avoid_print
    final preview = response.body.length > 400
        ? '${response.body.substring(0, 400)}...'
        : response.body;
    print('[OrdersRepository] ${response.statusCode} ${response.request?.url}\n$preview');
  }
}
