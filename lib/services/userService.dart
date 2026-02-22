import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_wallet_app/utils/constants.dart';

class UserService {
  final storage = const FlutterSecureStorage();
  static const String baseUrl = AppConstants.apiBaseUrl;

  Future<void> updateProfile({
    required String name,
    String? profileImage,
  }) async {
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        if (profileImage != null) 'profileImage': profileImage,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }
}
