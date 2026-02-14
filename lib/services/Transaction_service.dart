import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/transaction_model.dart';

class TransactionService {
  final ApiService _api = ApiService();

  // Get all transactions for a wallet
  Future<List<TransactionModel>> getWalletTransactions(String walletId) async {
    final response = await _api.get('/transactions/wallet/$walletId');
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(
      String walletId,
      String categoryId,
      ) async {
    final response = await _api.get('/transactions/wallet/$walletId/category/$categoryId');
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get transactions by type (expense or income)
  Future<List<TransactionModel>> getTransactionsByType(
      String walletId,
      String type,
      ) async {
    final response = await _api.get('/transactions/wallet/$walletId/type/$type');
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get transactions for a date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
      String walletId,
      String startDate,
      String endDate,
      ) async {
    final response = await _api.get(
      '/transactions/wallet/$walletId/range?start=$startDate&end=$endDate',
    );
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }
}