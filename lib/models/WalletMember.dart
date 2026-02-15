// wallet_member.dart
import 'package:meta/meta.dart';

@immutable
class WalletMember {
  final String id;
  final String userId;
  final String walletId;
  final DateTime joinedAt;

  const WalletMember({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.joinedAt,
  });

  factory WalletMember.fromJson(Map<String, dynamic> json) {
    return WalletMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
