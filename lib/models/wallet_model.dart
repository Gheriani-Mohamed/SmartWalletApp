class WalletModel {
  final String id;
  final String name;
  final String type; // 'personal', 'family', 'company'
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WalletMember> members;

  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });

  // Check if wallet is shared
  bool get isShared => members.length > 1;

  // Get member count
  int get memberCount => members.length;

  // From JSON
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'personal',
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      members: (json['members'] as List?)
          ?.map((m) => WalletMember.fromJson(m))
          .toList() ?? [],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
    };
  }
}

class WalletMember {
  final String id;
  final String userId;
  final String walletId;
  final DateTime joinedAt;
  final UserInfo user;

  WalletMember({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.joinedAt,
    required this.user,
  });

  factory WalletMember.fromJson(Map<String, dynamic> json) {
    return WalletMember(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt']),
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

class UserInfo {
  final String id;
  final String name;
  final String email;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}