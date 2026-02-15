// recurring_transaction.dart
import 'package:meta/meta.dart';

@immutable
class RecurringTransaction {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime lastGenerated;
  final bool isActive;
  final DateTime createdAt;

  // Relations
  final List<String> transactionIds; // Generated transactions from this template

  const RecurringTransaction({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.lastGenerated,
    required this.isActive,
    required this.createdAt,
    this.transactionIds = const [],
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String?,
      frequency: json['frequency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      lastGenerated: DateTime.parse(json['lastGenerated'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      transactionIds: (json['transactions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastGenerated': lastGenerated.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactionIds,
    };
  }
}
