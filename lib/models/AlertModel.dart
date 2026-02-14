class AlertModel {
  final String id;
  final String userId;
  final String budgetId;
  final String message;
  final String alertType; // 'warning', 'danger', 'info'
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

  // Check alert severity
  bool get isWarning => alertType == 'warning';
  bool get isDanger => alertType == 'danger';
  bool get isInfo => alertType == 'info';

  // From JSON (API response)
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

  // To JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'budgetId': budgetId,
      'message': message,
      'alertType': alertType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}