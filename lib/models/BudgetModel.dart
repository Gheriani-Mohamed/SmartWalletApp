class BudgetModel {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;        // CHANGED: was 'category'
  final double monthlyLimit;
  final String month;
  final double currentSpent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Category details if included from backend
  final CategoryDetails? category;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.currentSpent,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.category,
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

  // From JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      categoryId: json['categoryId'] ?? '',  // CHANGED
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      month: json['month'] ?? '',
      currentSpent: (json['currentSpent'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      category: json['category'] != null
          ? CategoryDetails.fromJson(json['category'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,  // CHANGED
      'monthlyLimit': monthlyLimit,
      'month': month,
      'currentSpent': currentSpent,
      'isActive': isActive,
    };
  }
}

// Helper class for category details
class CategoryDetails {
  final String id;
  final String name;
  final String iconName;
  final String colorValue;
  final String type;

  CategoryDetails({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconName: json['iconName'] ?? '',
      colorValue: json['colorValue'] ?? '',
      type: json['type'] ?? '',
    );
  }
}