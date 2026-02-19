import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';

class WalletService {
  final ApiService _api = ApiService();

  Future<List<Wallet>> getWallets() async {
    final response = await _api.get('/wallets');
    return (response as List).map((e) => Wallet.fromJson(e)).toList();
  }

  Future<Wallet?> createWallet({
    required String name,
    required String type,
    required double balance,
  }) async {
    final response = await _api.post('/wallets', {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': 'USD',
    });

    return Wallet.fromJson(response);
  }

  Future<Wallet?> updateBalance(String id, double balance) async {
    final response = await _api.put('/wallets/$id', {
      'balance': balance,
    });

    return Wallet.fromJson(response);
  }

  Future<void> deleteWallet(String id) async {
    await _api.delete('/wallets/$id');
  }
}