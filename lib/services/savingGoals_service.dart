import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/savingGoalsModel.dart';

class SavingGoalService {
  final ApiService _api = ApiService();

  // Get all saving goals for a user
  Future<List<SavingGoal>> getUserSavingGoals(String userId) async {
    final response = await _api.get('/saving-goals/user/$userId');
    if (response is List) {
      return response
          .map((json) => SavingGoal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get saving goals for a specific wallet
  Future<List<SavingGoal>> getWalletSavingGoals(String walletId) async {
    final response = await _api.get('/saving-goals/wallet/$walletId');
    if (response is List) {
      return response
          .map((json) => SavingGoal.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get single saving goal by ID
  Future<SavingGoal?> getSavingGoalById(String goalId) async {
    final response = await _api.get('/saving-goals/$goalId');
    if (response is Map<String, dynamic>) {
      return SavingGoal.fromJson(response);
    }
    return null;
  }
}
