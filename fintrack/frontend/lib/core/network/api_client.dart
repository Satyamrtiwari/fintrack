import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  final StorageService storageService;
  final Function()? onUnauthorized;

  ApiClient({
    required this.storageService,
    this.onUnauthorized,
  });

  String get baseUrl {
    final customUrl = storageService.getBaseUrl();
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    return ApiConstants.defaultBaseUrl;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = storageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: sanitizedParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please verify the API server is running at $baseUrl',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please verify the API server is running at $baseUrl',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please verify the API server is running at $baseUrl',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to server. Please verify the API server is running at $baseUrl',
      );
    } on TimeoutException {
      throw ApiException('Connection timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    String errorMessage = 'Server error ($statusCode)';
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        if (parsed.containsKey('detail')) {
          final detail = parsed['detail'];
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List) {
            errorMessage = detail
                .map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString())
                .join(', ');
          }
        } else if (parsed.containsKey('message')) {
          errorMessage = parsed['message'].toString();
        }
      }
    } catch (_) {
      if (body.isNotEmpty) errorMessage = body;
    }

    if (statusCode == 401) {
      storageService.clearToken();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
      throw ApiException('Session expired or unauthorized. Please log in again.', 401);
    }

    throw ApiException(errorMessage, statusCode);
  }
}
