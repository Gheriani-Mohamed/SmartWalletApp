import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String userId;
  final String budgetId;
  final String message;
  final String alertType; // 'info', 'warning', 'danger'
  final bool isRead;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.budgetId,
    required this.message,
    required this.alertType,
    required this.isRead,
    required this.createdAt,
  });

  Color get color {
    switch (alertType) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (alertType) {
      case 'danger':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      budgetId: json['budgetId'] ?? '',
      message: json['message'] ?? '',
      alertType: json['alertType'] ?? 'info',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'budgetId': budgetId,
      'message': message,
      'alertType': alertType,
    };
  }
}