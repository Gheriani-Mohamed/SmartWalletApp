// wallet.dart
import 'package:meta/meta.dart';

@immutable
class Wallet {
  final String id;
  final String name;
  final String type; // 'personal', 'family', 'company'
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (store IDs only)
  final List<String> memberIds;
  final List<String> transactionIds;
  final List<String> budgetIds;
  final List<String> savingGoalIds;
  final List<String> recurringTransactionIds;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.memberIds = const [],
    this.transactionIds = const [],
    this.budgetIds = const [],
    this.savingGoalIds = const [],
    this.recurringTransactionIds = const [],
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      memberIds: (json['members'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      transactionIds: (json['transactions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      budgetIds: (json['budgets'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      savingGoalIds: (json['savingGoals'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      recurringTransactionIds: (json['recurringTransactions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'members': memberIds,
      'transactions': transactionIds,
      'budgets': budgetIds,
      'savingGoals': savingGoalIds,
      'recurringTransactions': recurringTransactionIds,
    };
  }
}
