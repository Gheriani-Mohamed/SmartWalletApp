class BudgetModel {
  final String budgetId;
  final String category;
  final DateTime createdAt;
  final double currentSpent;
  final bool isActive;
  final String month;
  final double monthlyLimit;
  final DateTime updatedAt;
  final String userId;
  final String walletId;

  BudgetModel({
    required this.budgetId,
    required this.category,
    required this.createdAt,
    required this.currentSpent,
    required this.isActive,
    required this.month,
    required this.monthlyLimit,
    required this.updatedAt,
    required this.userId,
    required this.walletId,
  });

  // Calculated properties
  double get percentageSpent {
    if (monthlyLimit == 0) return 0;
    return (currentSpent / monthlyLimit) * 100;
  }

  bool get isOverspent => currentSpent > monthlyLimit;
  bool get isNearLimit => percentageSpent >= 90;
  bool get isAtWarning => percentageSpent >= 75;
  double get remainingAmount => monthlyLimit - currentSpent;

  // From JSON (API response)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      budgetId: json['budgetId'] ?? json['id'] ?? '',
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      currentSpent: (json['currentSpent'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      month: json['month'] ?? '',
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
    );
  }

  // To JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'currentSpent': currentSpent,
      'isActive': isActive,
      'month': month,
      'monthlyLimit': monthlyLimit,
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'walletId': walletId,
    };
  }
}