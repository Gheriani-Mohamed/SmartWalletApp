import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String colorValue;  // CHANGED: Now String instead of int
  final String type; // 'expense' or 'income'
  final bool isCustom;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
    required this.isCustom,
  });

  // Get Flutter Color from string colorValue
  Color get color {
    try {
      return Color(int.parse(colorValue));
    } catch (e) {
      return Colors.grey; // Fallback color
    }
  }

  // From JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconName: json['iconName'] ?? '',
      colorValue: json['colorValue'] ?? '0',  // CHANGED: String
      type: json['type'] ?? 'expense',
      isCustom: json['isCustom'] ?? false,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,  // CHANGED: String
      'type': type,
      'isCustom': isCustom,
    };
  }
}