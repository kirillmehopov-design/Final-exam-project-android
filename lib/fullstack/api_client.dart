import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static const defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  final String baseUrl;
  final http.Client httpClient;
  String? token;

  ApiClient({this.baseUrl = defaultUrl, http.Client? client})
      : httpClient = client ?? http.Client();

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, [Object? data]) => _request('POST', path, data);
  Future<dynamic> patch(String path, Object data) => _request('PATCH', path, data);

  Future<dynamic> _request(String method, String path, [Object? data]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await httpClient.post(uri, headers: headers,
              body: jsonEncode(data ?? <String, dynamic>{})).timeout(const Duration(seconds: 12));
          break;
        case 'PATCH':
          response = await httpClient.patch(uri, headers: headers,
              body: jsonEncode(data)).timeout(const Duration(seconds: 12));
          break;
        default:
          response = await httpClient.get(uri, headers: headers)
              .timeout(const Duration(seconds: 12));
      }
    } catch (e) {
      throw ApiException('Cannot connect to API ($baseUrl). Start the backend. $e');
    }
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map ? body['detail'] : null;
      throw ApiException(detail is String ? detail : 'Server error: ${response.statusCode}');
    }
    return body;
  }

  void dispose() => httpClient.close();
}
