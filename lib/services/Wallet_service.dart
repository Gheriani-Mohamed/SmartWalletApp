import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';

class WalletService {
  final ApiService _api = ApiService();

  // ==================== WALLET CRUD ====================

  // Create wallet
  Future<WalletModel> createWallet({
    required String userId,
    required String name,
    required String type,
    double balance = 0.0,
    String currency = 'USD',
  }) async {
    final response = await _api.post('/wallets', {
      'userId': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
    });

    return WalletModel.fromJson(response);
  }

  // Get all wallets for user
  Future<List<WalletModel>> getUserWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  // Get single wallet
  Future<WalletModel> getWalletById(String walletId) async {
    final response = await _api.get('/wallets/$walletId');
    return WalletModel.fromJson(response);
  }

  // Update wallet
  Future<WalletModel> updateWallet(
      String walletId,
      Map<String, dynamic> data,
      ) async {
    final response = await _api.put('/wallets/$walletId', data);
    return WalletModel.fromJson(response);
  }

  // Update balance
  Future<WalletModel> updateBalance(String walletId, double amount) async {
    final response = await _api.put('/wallets/$walletId/balance', {
      'amount': amount,
    });
    return WalletModel.fromJson(response);
  }

  // Delete wallet
  Future<void> deleteWallet(String walletId) async {
    await _api.delete('/wallets/$walletId');
  }

  // ==================== MEMBER MANAGEMENT ====================

  // Add member by email
  Future<WalletMember> addMember(String walletId, String email) async {
    final response = await _api.post('/wallets/$walletId/members', {
      'email': email,
    });
    return WalletMember.fromJson(response);
  }

  // Remove member
  Future<void> removeMember(String walletId, String userId) async {
    await _api.delete('/wallets/$walletId/members/$userId');
  }

  // Get members
  Future<List<WalletMember>> getMembers(String walletId) async {
    final response = await _api.get('/wallets/$walletId/members');
    return (response as List)
        .map((json) => WalletMember.fromJson(json))
        .toList();
  }

  // Check access
  Future<bool> checkAccess(String walletId, String userId) async {
    final response = await _api.get('/wallets/$walletId/access/$userId');
    return response['hasAccess'] ?? false;
  }

  // ==================== QUERIES ====================

  // Get shared wallets
  Future<List<WalletModel>> getSharedWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/shared');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  // Get personal wallets
  Future<List<WalletModel>> getPersonalWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/personal');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }
}