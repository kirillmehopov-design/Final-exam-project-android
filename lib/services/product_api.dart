import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductApiException implements Exception {
  ProductApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ProductApi {
  ProductApi({http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client;

  static final Uri productsUri = Uri.parse('https://fakestoreapi.com/products');

  final http.Client? _client;
  final Duration timeout;

  Future<List<Product>> fetchProducts() async {
    try {
      // Production uses http.get; tests inject a MockClient for the same GET.
      final request = _client == null
          ? http.get(productsUri)
          : _client.get(productsUri);
      final response = await request.timeout(timeout);

      if (response.statusCode == 404) {
        throw ProductApiException('404: Products endpoint not found.', statusCode: 404);
      }
      if (response.statusCode >= 500) {
        throw ProductApiException(
          '${response.statusCode}: Server error. Please try again later.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode != 200) {
        throw ProductApiException(
          'Request failed: HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('The API returned an unexpected JSON format.');
      }
      return decoded.map((item) {
        if (item is! Map) {
          throw const FormatException('One product is not a JSON object.');
        }
        return Product.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on ProductApiException {
      rethrow;
    } on TimeoutException {
      throw ProductApiException('Connection timed out after 10 seconds. Check your internet and retry.');
    } on http.ClientException {
      throw ProductApiException('Network request failed. You may be offline. Check your connection and retry.');
    } on FormatException catch (error) {
      throw ProductApiException('Invalid server data: ${error.message}');
    } catch (_) {
      throw ProductApiException('Could not load products. Please retry the connection.');
    }
  }

  // The top-level http.get closes its own temporary Client. A Client passed
  // to ProductApi is owned by the caller (for example, a test).
  void dispose() {}
}
