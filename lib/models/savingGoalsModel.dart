import 'package:flutter/material.dart';

class SavingGoalModel {
  final String id;
  final String userId;
  final String walletId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCompleted;
  final DateTime createdAt;

  SavingGoalModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.startDate,
    this.endDate,
    required this.isCompleted,
    required this.createdAt,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0);
  }

  // Remaining amount to goal
  double get remainingAmount => targetAmount - currentAmount;

  // Is goal reached
  bool get isReached => currentAmount >= targetAmount;

  // Progress color
  Color get progressColor {
    if (isCompleted) return Colors.green;
    if (progressPercentage >= 75) return Colors.blue;
    if (progressPercentage >= 50) return Colors.orange;
    return Colors.grey;
  }

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) {
    return SavingGoalModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      title: json['title'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      startDate: json['startDate'] is String ? DateTime.parse(json['startDate']) : json['startDate'] is DateTime ? json['startDate'] : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : json['createdAt'] is DateTime ? json['createdAt'] : DateTime.now(),   );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'targetAmount': targetAmount,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate?.toIso8601String().split('T')[0],
    };
  }
}