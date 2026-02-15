import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';

class RecurringTransactionService {
  final ApiService _api = ApiService();

  // Get all recurring transactions for a user
  Future<List<RecurringTransaction>> getUserRecurringTransactions(String userId) async {
    final response = await _api.get('/recurring-transactions/user/$userId');
    if (response is List) {
      return response
          .map((json) => RecurringTransaction.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get all recurring transactions for a wallet
  Future<List<RecurringTransaction>> getWalletRecurringTransactions(String walletId) async {
    final response = await _api.get('/recurring-transactions/wallet/$walletId');
    if (response is List) {
      return response
          .map((json) => RecurringTransaction.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get single recurring transaction by ID
  Future<RecurringTransaction?> getRecurringTransactionById(String id) async {
    final response = await _api.get('/recurring-transactions/$id');
    if (response is Map<String, dynamic>) {
      return RecurringTransaction.fromJson(response);
    }
    return null;
  }
}
