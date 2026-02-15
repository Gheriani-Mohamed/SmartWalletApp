import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';

class WalletService {
  final ApiService _api = ApiService();

  // Get all wallets for a user
  Future<List<Wallet>> getUserWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId');
    if (response is List) {
      return response
          .map((json) => Wallet.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get single wallet by ID
  Future<Wallet?> getWalletById(String walletId) async {
    final response = await _api.get('/wallets/$walletId');
    if (response is Map<String, dynamic>) {
      return Wallet.fromJson(response);
    }
    return null;
  }

  // Get shared wallets for a user
  Future<List<Wallet>> getSharedWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/shared');
    if (response is List) {
      return response
          .map((json) => Wallet.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get personal wallets for a user
  Future<List<Wallet>> getPersonalWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/personal');
    if (response is List) {
      return response
          .map((json) => Wallet.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }
}
