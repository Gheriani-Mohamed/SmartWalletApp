import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_wallet_app/utils/constants.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();


  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
      print('GET: $url');
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      rethrow; // ✅ rethrow so the real message bubbles up
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
      print('POST: $url');
      print('Data: $data');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('POST Error: $e');
      rethrow; // ✅ rethrow so the real message bubbles up
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
      print('PUT: $url');
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      rethrow; // ✅ rethrow so the real message bubbles up
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
      print('DELETE: $url');
      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      rethrow; // ✅ rethrow so the real message bubbles up
    }
  }

  dynamic _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // ✅ Fixed: parse error message without swallowing it
    String errorMessage = 'Request failed: ${response.statusCode}';
    if (response.body.isNotEmpty) {
      try {
        final body = json.decode(response.body);
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      } catch (_) {
        // body wasn't JSON, use status code message
      }
    }
    throw Exception(errorMessage);
  }
}