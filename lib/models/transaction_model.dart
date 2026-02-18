class TransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final DateTime date;
  final String? recurringTransactionId;

  // Optional: Category details if included from backend
  final CategoryDetails? category;
  final WalletInfo? wallet;

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
    this.wallet,
  });

  // From JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'expense',
      description: json['description'],
      date: DateTime.parse(json['date']),
      recurringTransactionId: json['recurringTransactionId'],
      category: json['category'] != null
          ? CategoryDetails.fromJson(json['category'])
          : null,
      wallet: json['wallet'] != null
          ? WalletInfo.fromJson(json['wallet'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}

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

class WalletInfo {
  final String id;
  final String name;
  final String type;

  WalletInfo({
    required this.id,
    required this.name,
    required this.type,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}