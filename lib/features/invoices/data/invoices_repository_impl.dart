import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/static.dart';
import '../domain/entities/invoice.dart';
import '../domain/entities/invoice_page.dart';
import '../domain/repositories/invoices_repository.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  InvoicesRepositoryImpl({http.Client? client, this.baseUrl = Static.baseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<InvoicePage> fetchInvoices({
    required String token,
    int page = 1,
    int limit = 10,
    String search = '',
    int? paymentStatus,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (paymentStatus != null) {
      query['payment_status'] = paymentStatus.toString();
    }

    final uri = Uri.parse('${baseUrl}customer/invoice/list').replace(
      queryParameters: query,
    );
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
    final meta = data['meta'] as Map<String, dynamic>? ?? const {};
    final list = data['data'] as List<dynamic>? ?? const [];

    final invoices = list
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList();

    return InvoicePage(
      invoices: invoices,
      currentPage: _asInt(meta['currentPage']) ?? page,
      lastPage: _asInt(meta['lastPage']) ?? page,
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? 'Something went wrong';
    } catch (_) {
      return 'Something went wrong';
    }
  }

  void _logRequest(String method, Uri uri, {Object? body}) {
    // ignore: avoid_print
    print('[INVOICE-REQUEST] $method $uri${body != null ? ' body=$body' : ''}');
  }

  void _logResponse(http.Response response) {
    // ignore: avoid_print
    print(
        '[INVOICE-RESPONSE] ${response.request?.url} ${response.statusCode} ${response.body}');
  }
}
