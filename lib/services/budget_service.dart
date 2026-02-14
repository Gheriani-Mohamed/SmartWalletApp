import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/BudgetModel.dart';

class BudgetService {
  final ApiService _api = ApiService();

  // Get all budgets for a user
  Future<List<BudgetModel>> getUserBudgets(String userId) async {
    final response = await _api.get('/budgets/user/$userId');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get budgets for a specific wallet
  Future<List<BudgetModel>> getWalletBudgets(String walletId) async {
    final response = await _api.get('/budgets/wallet/$walletId');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get budgets for a specific month
  Future<List<BudgetModel>> getMonthlyBudgets(String userId, String month) async {
    final response = await _api.get('/budgets/month/$userId/$month');
    return (response as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  // Get single budget by ID
  Future<BudgetModel> getBudgetById(String budgetId) async {
    final response = await _api.get('/budgets/$budgetId');
    return BudgetModel.fromJson(response);
  }
}