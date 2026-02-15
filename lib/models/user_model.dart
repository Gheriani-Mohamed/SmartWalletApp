// user.dart
import 'package:meta/meta.dart';

@immutable
class User {
  final String id;
  final String email;
  final String password; // hashed
  final String name;
  final DateTime createdAt;

  // Relations (store IDs only for simplicity)
  final List<String> walletMemberIds;
  final List<String> transactionIds;
  final List<String> budgetIds;
  final List<String> alertIds;
  final List<String> savingGoalIds;
  final List<String> recurringTransactionIds;

  const User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.createdAt,
    this.walletMemberIds = const [],
    this.transactionIds = const [],
    this.budgetIds = const [],
    this.alertIds = const [],
    this.savingGoalIds = const [],
    this.recurringTransactionIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      walletMemberIds: (json['walletMembers'] as List<dynamic>?)
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
      alertIds: (json['alerts'] as List<dynamic>?)
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
      'email': email,
      'password': password,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'walletMembers': walletMemberIds,
      'transactions': transactionIds,
      'budgets': budgetIds,
      'alerts': alertIds,
      'savingGoals': savingGoalIds,
      'recurringTransactions': recurringTransactionIds,
    };
  }
}
