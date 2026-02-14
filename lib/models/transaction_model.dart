class TransactionModel {
  final double amount;
  final String categoryId;
  final DateTime date;
  final String description;
  final String type; // 'expense' or 'income'
  final String walletId;

  TransactionModel({
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.description,
    required this.type,
    required this.walletId,
  });

  // From JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      amount: (json['amount'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
      type: json['type'] ?? 'expense',
      walletId: json['walletId'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'type': type,
      'walletId': walletId,
    };
  }
}