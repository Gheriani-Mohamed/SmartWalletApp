import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/savingGoalsModel.dart';

class SavingGoalService {
  final ApiService _api = ApiService();

  Future<SavingGoalModel> createGoal({
    required String userId,
    required String walletId,
    required String title,
    required double targetAmount,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final startDateString = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDateString = endDate != null
        ? '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
        : null;

    final response = await _api.post('/saving-goals', {
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'targetAmount': targetAmount,
      'startDate': startDateString,
      'endDate': endDateString,
    });

    return SavingGoalModel.fromJson(response);
  }

  Future<List<SavingGoalModel>> getWalletGoals(String walletId) async {
    final response = await _api.get('/saving-goals/wallet/$walletId');
    return (response as List)
        .map((json) => SavingGoalModel.fromJson(json))
        .toList();
  }

  Future<SavingGoalModel> getGoalById(String id) async {
    final response = await _api.get('/saving-goals/$id');
    return SavingGoalModel.fromJson(response);
  }

  Future<SavingGoalModel> addContribution(String goalId, double amount) async {
    final response = await _api.post('/saving-goals/$goalId/contribute', {
      'amount': amount,
    });
    return SavingGoalModel.fromJson(response);
  }

  Future<SavingGoalModel> withdraw(String goalId, double amount) async {
    final response = await _api.post('/saving-goals/$goalId/withdraw', {
      'amount': amount,
    });
    return SavingGoalModel.fromJson(response);
  }

  Future<void> deleteGoal(String goalId) async {
    await _api.delete('/saving-goals/$goalId');
  }
}