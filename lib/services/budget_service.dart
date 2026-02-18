import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/BudgetModel.dart';

class BudgetService {
  final ApiService _api = ApiService();

  // Create budget
  Future<BudgetModel> createBudget({
    required String userId,
    required String walletId,
    required String categoryId,
    required double monthlyLimit,
    required String month,
  }) async {
    final response = await _api.post('/budgets', {
      'userId': userId,
      'walletId': walletId,
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
      'month': month,
    });

    return BudgetModel.fromJson(response);
  }

  // Get user budgets
  Future<List<BudgetModel>> getUserBudgets(String userId) async {
    final response = await _api.get('/budgets/user/$userId');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get wallet budgets
  Future<List<BudgetModel>> getWalletBudgets(String walletId) async {
    final response = await _api.get('/budgets/wallet/$walletId');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get wallet budgets for specific month
  Future<List<BudgetModel>> getWalletMonthlyBudgets(String walletId, String month) async {
    final response = await _api.get('/budgets/wallet/$walletId/month/$month');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get monthly budgets (for user - all wallets)
  Future<List<BudgetModel>> getMonthlyBudgets(String userId, String month) async {
    final response = await _api.get('/budgets/month/$userId/$month');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get single budget
  Future<BudgetModel> getBudgetById(String budgetId) async {
    final response = await _api.get('/budgets/$budgetId');
    return BudgetModel.fromJson(response);
  }

  // Update budget
  Future<BudgetModel> updateBudget(
      String budgetId,
      Map<String, dynamic> data,
      ) async {
    final response = await _api.put('/budgets/$budgetId', data);
    return BudgetModel.fromJson(response);
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    await _api.delete('/budgets/$budgetId');
  }

  // Sync budget with transactions
  Future<BudgetModel> syncBudget(String budgetId) async {
    final response = await _api.post('/budgets/sync/$budgetId', {});
    return BudgetModel.fromJson(response);
  }

  // Sync all user budgets
  Future<void> syncAllBudgets(String userId) async {
    await _api.post('/budgets/sync-all/$userId', {});
  }

  // Helper: Get current month
  static String getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}