import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:7097/api';
  static const int timeoutSeconds = 15; // Reduced from 30 to 15 seconds

  // Get headers with authentication
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    } catch (e) {
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }

  // Handle API response
  static dynamic _handleResponse(http.Response response) {
    final String responseBodyString = utf8.decode(response.bodyBytes);

    if (responseBodyString.isEmpty) {
      throw ApiException(
        message: 'Empty response from server',
        statusCode: response.statusCode,
      );
    }

    final dynamic responseBody;
    try {
      responseBody = json.decode(responseBodyString);
    } catch (e) {
      throw ApiException(
        message: 'Invalid JSON response: $e',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw ApiException(
        message: responseBody['message']?.toString() ??
            responseBody['error']?.toString() ??
            'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        responseData: responseBody,
      );
    }
  }

  // Generic GET request
  static Future<dynamic> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final headers = await _getHeaders();
      Uri uri = Uri.parse('$baseUrl$endpoint');

      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) =>
            MapEntry(key, value.toString())));
      }

      print('API GET: $uri'); // Debug log

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Server connection failed: $e', statusCode: 0);
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  // Generic POST request
  static Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');

      print('API POST: $uri'); // Debug log
      print('API Data: $data'); // Debug log

      final response = await http
          .post(
        uri,
        headers: headers,
        body: json.encode(data),
      )
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Server connection failed: $e', statusCode: 0);
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  // Generic PUT request
  static Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .put(uri, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Server connection failed: $e', statusCode: 0);
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  // Generic DELETE request
  static Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(message: 'No internet connection. Please check your network.', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException(message: 'Server connection failed: $e', statusCode: 0);
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic responseData;

  ApiException({
    required this.message,
    required this.statusCode,
    this.responseData,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}