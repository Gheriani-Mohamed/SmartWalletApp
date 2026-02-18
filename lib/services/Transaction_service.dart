import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/transaction_model.dart';

class TransactionService {
  final ApiService _api = ApiService();

  // Create transaction
  Future<TransactionModel> createTransaction({
    required String userId,
    required String walletId,
    required String categoryId,
    required double amount,
    required String type,
    String? description,
    DateTime? date,
  }) async {
    final response = await _api.post('/transactions', {
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'date': (date ?? DateTime.now()).toIso8601String(),
    });

    return TransactionModel.fromJson(response);
  }

  // Get wallet transactions
  Future<List<TransactionModel>> getWalletTransactions(
      String walletId, {
        int? limit,
      }) async {
    final endpoint = limit != null
        ? '/transactions/wallet/$walletId?limit=$limit'
        : '/transactions/wallet/$walletId';

    final response = await _api.get(endpoint);
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get user transactions
  Future<List<TransactionModel>> getUserTransactions(
      String userId, {
        int? limit,
      }) async {
    final endpoint = limit != null
        ? '/transactions/user/$userId?limit=$limit'
        : '/transactions/user/$userId';

    final response = await _api.get(endpoint);
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get by category
  Future<List<TransactionModel>> getByCategory(
      String walletId,
      String categoryId,
      ) async {
    final response = await _api.get('/transactions/wallet/$walletId/category/$categoryId');
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get by type
  Future<List<TransactionModel>> getByType(
      String walletId,
      String type,
      ) async {
    final response = await _api.get('/transactions/wallet/$walletId/type/$type');
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get by date range
  Future<List<TransactionModel>> getByDateRange(
      String walletId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final response = await _api.get(
      '/transactions/wallet/$walletId/range?startDate=$start&endDate=$end',
    );
    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Get statistics
  Future<Map<String, dynamic>> getWalletStats(
      String walletId, {
        String? month,
      }) async {
    final endpoint = month != null
        ? '/transactions/wallet/$walletId/stats?month=$month'
        : '/transactions/wallet/$walletId/stats';

    return await _api.get(endpoint);
  }

  // Update transaction
  Future<TransactionModel> updateTransaction(
      String transactionId,
      Map<String, dynamic> data,
      ) async {
    final response = await _api.put('/transactions/$transactionId', data);
    return TransactionModel.fromJson(response);
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _api.delete('/transactions/$transactionId');
  }
}