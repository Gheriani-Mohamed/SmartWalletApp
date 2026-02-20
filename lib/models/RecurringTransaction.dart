import 'package:flutter/material.dart';

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final double amount;
  final String type;
  final String? description;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime lastGenerated;
  final bool isActive;
  final DateTime createdAt;

  RecurringTransactionModel({
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
  });

  DateTime get nextOccurrence {
    DateTime next = lastGenerated;

    switch (frequency) {
      case 'daily':
        next = next.add(const Duration(days: 1));
        break;
      case 'weekly':
        next = next.add(const Duration(days: 7));
        break;
      case 'monthly':
        next = DateTime(next.year, next.month + 1, next.day);
        break;
      case 'yearly':
        next = DateTime(next.year + 1, next.month, next.day);
        break;
    }

    return next;
  }

  bool get isOverdue {
    // Strip time to compare dates at midnight
    final nextMidnight = DateTime(
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
    );

    final todayWithTime = DateTime.now();

    // Overdue if next date is BEFORE today (not including today)
    return nextMidnight.isBefore(todayWithTime);
  }

  String get frequencyDisplay {
    switch (frequency) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'yearly': return 'Yearly';
      default: return frequency;
    }
  }

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'expense',
      description: json['description'],
      frequency: json['frequency'] ?? 'monthly',
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      lastGenerated: DateTime.parse(json['lastGenerated']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}