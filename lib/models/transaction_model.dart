class TransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;  // CHANGED: was 'category'
  final double amount;
  final String type; // 'expense' or 'income'
  final String? description;
  final DateTime date;
  final String? recurringTransactionId;

  // Optional: Category details if included from backend
  final CategoryDetails? category;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.recurringTransactionId,
    this.category,
  });

  // From JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      categoryId: json['categoryId'] ?? '',  // CHANGED
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'expense',
      description: json['description'],
      date: DateTime.parse(json['date']),
      recurringTransactionId: json['recurringTransactionId'],
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
      'amount': amount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'recurringTransactionId': recurringTransactionId,
    };
  }
}

// Helper class for category details
class CategoryDetails {
  final String id;
  final String name;
  final String iconName;
  final String colorValue;

  CategoryDetails({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconName: json['iconName'] ?? '',
      colorValue: json['colorValue'] ?? '',
    );
  }
}