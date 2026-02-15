// alert.dart
import 'package:meta/meta.dart';

@immutable
class Alert {
  final String id;
  final String userId;
  final String budgetId;
  final String message;
  final AlertType alertType;
  final bool isRead;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.userId,
    required this.budgetId,
    required this.message,
    required this.alertType,
    required this.isRead,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      budgetId: json['budgetId'] as String,
      message: json['message'] as String,
      alertType: _alertTypeFromString(json['alertType'] as String),
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'budgetId': budgetId,
      'message': message,
      'alertType': _alertTypeToString(alertType),
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AlertType _alertTypeFromString(String value) {
    switch (value) {
      case 'warning':
        return AlertType.warning;
      case 'danger':
        return AlertType.danger;
      case 'info':
        return AlertType.info;
      default:
        throw ArgumentError('Unknown alertType: $value');
    }
  }

  static String _alertTypeToString(AlertType type) {
    switch (type) {
      case AlertType.warning:
        return 'warning';
      case AlertType.danger:
        return 'danger';
      case AlertType.info:
        return 'info';
    }
  }
}

enum AlertType { warning, danger, info }
