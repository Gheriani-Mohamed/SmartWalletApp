import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/RecurringTransaction.dart';

class RecurringTransactionService {
  final ApiService _api = ApiService();

  // Create recurring transaction
  Future<RecurringTransactionModel> createRecurring({
    required String userId,
    required String walletId,
    required String categoryId,
    required double amount,
    required String type,
    String? description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final response = await _api.post('/recurring-transactions', {
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });

    return RecurringTransactionModel.fromJson(response);
  }

  // Get user's recurring transactions
  Future<List<RecurringTransactionModel>> getUserRecurring(String userId) async {
    final response = await _api.get('/recurring-transactions/user/$userId');
    return (response as List)
        .map((json) => RecurringTransactionModel.fromJson(json))
        .toList();
  }

  // Get wallet's recurring transactions
  Future<List<RecurringTransactionModel>> getWalletRecurring(String walletId) async {
    final response = await _api.get('/recurring-transactions/wallet/$walletId');
    return (response as List)
        .map((json) => RecurringTransactionModel.fromJson(json))
        .toList();
  }

  // Get single recurring transaction
  Future<RecurringTransactionModel> getRecurringById(String id) async {
    final response = await _api.get('/recurring-transactions/$id');
    return RecurringTransactionModel.fromJson(response);
  }

  // Update recurring transaction
  Future<RecurringTransactionModel> updateRecurring(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _api.put('/recurring-transactions/$id', data);
    return RecurringTransactionModel.fromJson(response);
  }

  // Delete recurring transaction
  Future<void> deleteRecurring(String id) async {
    await _api.delete('/recurring-transactions/$id');
  }

  // Generate transactions for specific recurring
  Future<Map<String, dynamic>> generateTransactions(String id) async {
    final response = await _api.post('/recurring-transactions/$id/generate', {});
    return response;
  }

  // Generate all due transactions for user
  Future<Map<String, dynamic>> generateAllUserTransactions(String userId) async {
    final response = await _api.post('/recurring-transactions/user/$userId/generate-all', {});
    return response;
  }
}