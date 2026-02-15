import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/WalletMember.dart';

class WalletMemberService {
  final ApiService _api = ApiService();

  // Get all members of a wallet
  Future<List<WalletMember>> getWalletMembers(String walletId) async {
    final response = await _api.get('/wallet-members/wallet/$walletId');
    if (response is List) {
      return response
          .map((json) => WalletMember.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get all wallets a user belongs to
  Future<List<WalletMember>> getUserWalletMemberships(String userId) async {
    final response = await _api.get('/wallet-members/user/$userId');
    if (response is List) {
      return response
          .map((json) => WalletMember.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get a single membership by ID
  Future<WalletMember?> getMembershipById(String membershipId) async {
    final response = await _api.get('/wallet-members/$membershipId');
    if (response is Map<String, dynamic>) {
      return WalletMember.fromJson(response);
    }
    return null;
  }
}
