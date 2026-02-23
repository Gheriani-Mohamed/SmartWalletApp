import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_wallet_app/models/user_model.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class AuthService {
  final storage = const FlutterSecureStorage();
  static  String baseUrl = AppConstants.apiBaseUrl;

  // Register
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await storage.write(key: 'token', value: data['token']);
      await storage.write(key: 'userId', value: data['user']['id']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Registration failed');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await storage.write(key: 'token', value: data['token']);
      await storage.write(key: 'userId', value: data['user']['id']);
      return data;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Login failed');
    }
  }

  // Logout
  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'userId');
  }

  // Get token
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Get user ID
  Future<String?> getUserId() async {
    return await storage.read(key: 'userId');
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get current user
  Future<UserModel> getCurrentUser() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user');
    }
  }
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to send reset code');
    }
  }

// Reset password with code
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to reset password');
    }
  }
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to change password');
    }
  }
}