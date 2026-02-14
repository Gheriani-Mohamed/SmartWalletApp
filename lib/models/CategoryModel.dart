import 'package:flutter/material.dart';

class CategoryModel {
  final int colorValue;
  final String iconName;
  final bool isCustom;
  final String name;
  final String type; // 'expense' or 'income'

  CategoryModel({
    required this.colorValue,
    required this.iconName,
    required this.isCustom,
    required this.name,
    required this.type,
  });

  // Get Flutter Color from colorValue
  Color get color => Color(colorValue);

  // From JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      colorValue: json['colorValue'] ?? 0,
      iconName: json['iconName'] ?? '',
      isCustom: json['isCustom'] ?? false,
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'colorValue': colorValue,
      'iconName': iconName,
      'isCustom': isCustom,
      'name': name,
      'type': type,
    };
  }
}