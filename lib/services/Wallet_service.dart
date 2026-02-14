import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';

class WalletService {
  final ApiService _api = ApiService();

  // Get all wallets for a user
  Future<List<WalletModel>> getUserWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  // Get single wallet by ID
  Future<WalletModel> getWalletById(String walletId) async {
    final response = await _api.get('/wallets/$walletId');
    return WalletModel.fromJson(response);
  }

  // Get shared wallets for a user
  Future<List<WalletModel>> getSharedWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/shared');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  // Get personal wallets for a user
  Future<List<WalletModel>> getPersonalWallets(String userId) async {
    final response = await _api.get('/wallets/user/$userId/personal');
    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }
}