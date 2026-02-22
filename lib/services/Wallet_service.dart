import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/wallet_model.dart';

class WalletService {
  // Temporary hardcoded token for testing
  static const String _testToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c2VyNDU2IiwiZW1haWwiOiJ0ZXN0MkBleGFtcGxlLmNvbSIsImlhdCI6MTc3MTYwMzY1NywiZXhwIjoxNzcyMjA4NDU3fQ.Zouudv_70YmYT1m7_zPOLUiZC7IDcF7rtTMSCLQHgNk';

  final ApiService _api = ApiService();

  /// Get all wallets for the current user
  Future<List<Wallet>> getWallets() async {
    // temporarily save the token in ApiService for testing
    await _api.saveToken(_testToken);

    final response = await _api.get('/wallets');
    return (response as List).map((e) => Wallet.fromJson(e)).toList();
  }

  /// Create a new wallet (backend prevents duplicates per type)
  Future<Wallet?> createWallet({
    required String name,
    required String type,
    required double balance,
  }) async {
    await _api.saveToken(_testToken);

    final response = await _api.post('/wallets', {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': 'USD',
    });

    return Wallet.fromJson(response);
  }

  /// Update only wallet balance
  Future<Wallet?> updateBalance(String id, double balance) async {
    await _api.saveToken(_testToken);

    final response = await _api.put('/wallets/$id', {'balance': balance});
    return Wallet.fromJson(response);
  }

  /// Delete a wallet
  Future<void> deleteWallet(String id) async {
    await _api.saveToken(_testToken);

    await _api.delete('/wallets/$id');
  }
}