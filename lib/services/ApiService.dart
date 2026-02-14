import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();

  // Get JWT token ta3 wedhni
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Save JWT token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Delete token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Get headers with auth
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');

      print('GET: $url');

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  // POST request
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
      throw Exception('Failed to send data: $e');
    }
  }

  // PUT request
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
      throw Exception('Failed to update data: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');

      print('DELETE: $url');

      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Failed to delete data: $e');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed: ${response.statusCode}');
      }
    }
  }
}