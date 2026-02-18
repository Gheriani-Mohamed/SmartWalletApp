import 'package:flutter/material.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final double monthlyLimit;
  final String month; // "2026-02"
  final double currentSpent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Category details if included from backend
  final CategoryDetails? category;
  final WalletInfo? wallet;

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
    this.wallet,
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

  // Status color
  Color get statusColor {
    if (isOverspent) return Colors.red;
    if (isNearLimit) return Colors.orange;
    if (isAtWarning) return Colors.amber;
    return Colors.green;
  }

  // From JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      month: json['month'] ?? '',
      currentSpent: (json['currentSpent'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      'monthlyLimit': monthlyLimit,
      'month': month,
    };
  }
}

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