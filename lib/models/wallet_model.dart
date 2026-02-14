class WalletModel {
  final String id;
  final String name;
  final String type; // 'personal', 'family', 'company'
  final double balance;
  final List<String> sharedWith; // List of user IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.sharedWith,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if wallet is shared
  bool get isShared => sharedWith.length > 1;

  // From JSON
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'personal',
      balance: (json['balance'] ?? 0).toDouble(),
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'sharedWith': sharedWith,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}