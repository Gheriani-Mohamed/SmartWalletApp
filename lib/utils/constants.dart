import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  // For Android Emulator:
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

  // For iOS Simulator:
  // static const String apiBaseUrl = 'http://localhost:3000/api';

  // For Real Device :
  // static const String apiBaseUrl = 'http://192.168.1.XX:3000/api';

  // App Colors
  static const Color primaryGreen = Color(0xFF76A82F);
  static const Color darkGreen = Color(0xFF5C8424);

  // Budget Status Colors
  static const Color onTrackColor = Color(0xFF76A82F);
  static const Color warningColor = Colors.amber;
  static const Color dangerColor = Colors.orange;
  static const Color overspentColor = Colors.red;

  // Wallet Type Colors
  static const Color personalColor = Color(0xFF76A82F);
  static const Color familyColor = Colors.blue;
  static const Color companyColor = Colors.orange;
}