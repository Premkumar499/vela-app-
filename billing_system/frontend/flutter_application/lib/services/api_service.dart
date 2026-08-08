import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../utils/constants.dart';
import 'local_data.dart';

/// Result wrapper – every API call returns either data or an error message
/// without throwing exceptions into the UI layer.
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  /// True when data came from the local dummy dataset (backend unreachable).
  final bool isOffline;

  const ApiResult.ok(this.data, {this.isOffline = false})
      : error = null,
        success = true;

  const ApiResult.err(this.error)
      : data = null,
        success = false,
        isOffline = false;
}

/// Central HTTP client for the Flask backend.
/// Falls back to [LocalData] when the backend is unreachable so the UI
/// always shows meaningful data.
class ApiService {
  static final http.Client _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // -------------------------------------------------------------------------
  // Health
  // -------------------------------------------------------------------------

  /// Returns true when the backend is reachable.
  static Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('${AppConstants.baseUrl}/health'), headers: _headers)
          .timeout(AppConstants.connectionTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Products
  // -------------------------------------------------------------------------

  /// Fetch all products from the backend; falls back to [LocalData] on failure.
  static Future<ApiResult<List<Product>>> getProducts({
    String? search,
    String? category,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/products/').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['data'] as List<dynamic>)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.ok(list);
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      // ── Offline fallback ────────────────────────────────────────────────
      var fallback = List<Product>.from(LocalData.products);
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        fallback = fallback
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();
      }
      if (category != null && category.isNotEmpty) {
        fallback =
            fallback.where((p) => p.category == category).toList();
      }
      return ApiResult.ok(fallback, isOffline: true);
    }
  }

  // -------------------------------------------------------------------------
  // Customers
  // -------------------------------------------------------------------------

  /// Fetch all customers from the backend; falls back to [LocalData] on failure.
  static Future<ApiResult<List<Customer>>> getCustomers({
    String? search,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/customers/').replace(
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (body['data'] as List<dynamic>)
            .map((e) => Customer.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.ok(list);
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      // ── Offline fallback ────────────────────────────────────────────────
      var fallback = List<Customer>.from(LocalData.customers);
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        fallback = fallback
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                c.area.toLowerCase().contains(q))
            .toList();
      }
      return ApiResult.ok(fallback, isOffline: true);
    }
  }

  // -------------------------------------------------------------------------
  // Bills
  // -------------------------------------------------------------------------

  /// Submit a new bill to the backend.
  static Future<ApiResult<Map<String, dynamic>>> saveBill({
    required Customer customer,
    required List<BillItem> items,
    required String paymentType,
    String customerPhone = '',
    String salesType = 'Retail',
    String remarks = '',
    String through = '',
    String area = '',
    String priceList = 'Retail',
  }) async {
    try {
      final body = jsonEncode({
        'customer_id': customer.id,
        'customer_name': customer.name,
        'customer_phone': customerPhone,
        'payment_type': paymentType,
        'sales_type': salesType,
        'remarks': remarks,
        'through': through,
        'area': area,
        'price_list': priceList,
        'items': items.map((e) => e.toJson()).toList(),
      });

      final response = await _client
          .post(
            Uri.parse('${AppConstants.baseUrl}/bill/'),
            headers: _headers,
            body: body,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.ok(data);
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      return const ApiResult.err(
          'Cannot save bill: server is unreachable. Please start the Flask backend.');
    }
  }

  /// Fetch all saved bills (newest first).
  static Future<ApiResult<List<Bill>>> getBills() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.baseUrl}/bills/'),
            headers: _headers,
          )
          .timeout(AppConstants.requestTimeout);

      return _parseList<Bill>(response, (json) => Bill.fromJson(json));
    } catch (_) {
      // No local bill history — return empty list gracefully
      return ApiResult.ok(<Bill>[], isOffline: true);
    }
  }

  /// Fetch a single bill by [billNumber].
  static Future<ApiResult<Bill>> getBillDetails(String billNumber) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.baseUrl}/bills/$billNumber'),
            headers: _headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.ok(
            Bill.fromJson(body['data'] as Map<String, dynamic>));
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      return const ApiResult.err('Cannot reach server to load bill details.');
    }
  }

  /// Delete a bill by [billNumber].
  static Future<ApiResult<String>> deleteBill(String billNumber) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${AppConstants.baseUrl}/bills/$billNumber'),
            headers: _headers,
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.ok(body['message'] as String);
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      return const ApiResult.err(
          'Cannot delete bill: server is unreachable.');
    }
  }

  /// Create a new customer in the backend (saves to Supabase).
  static Future<ApiResult<Customer>> createCustomer({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConstants.baseUrl}/customers/'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'email': email,
              'address': address,
            }),
          )
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResult.ok(
            Customer.fromJson(body['data'] as Map<String, dynamic>));
      }
      return ApiResult.err(_extractError(response));
    } catch (_) {
      return const ApiResult.err('Cannot reach server to create customer.');
    }
  }

  /// Translate a list of texts to Tamil (or [target] language) via the backend.  /// Returns originals unchanged if the API key is not configured.
  static Future<List<String>> translateToTamil(List<String> texts,
      {String target = 'ta'}) async {
    if (texts.isEmpty) return texts;
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConstants.baseUrl}/translate/'),
            headers: _headers,
            body: jsonEncode({'texts': texts, 'target': target}),
          )
          .timeout(AppConstants.requestTimeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['translations'] as List<dynamic>?;
        if (list != null) return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return texts; // fall back to originals
  }


  // -------------------------------------------------------------------------

  static ApiResult<List<T>> _parseList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.ok(list);
    }
    return ApiResult.err(_extractError(response));
  }

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] as String? ??
          'Unknown error (${response.statusCode})';
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }
}
