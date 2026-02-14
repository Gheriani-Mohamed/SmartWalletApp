import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/savingGoalsModel.dart';

class SavingGoalService {
  final ApiService _api = ApiService();

  // Get all saving goals for a user
  Future<List<SavingGoalModel>> getUserSavingGoals(String userId) async {
    final response = await _api.get('/saving-goals/user/$userId');
    return (response as List)
        .map((json) => SavingGoalModel.fromJson(json))
        .toList();
  }

  // Get saving goals for a specific wallet
  Future<List<SavingGoalModel>> getWalletSavingGoals(String walletId) async {
    final response = await _api.get('/saving-goals/wallet/$walletId');
    return (response as List)
        .map((json) => SavingGoalModel.fromJson(json))
        .toList();
  }

  // Get single saving goal by ID
  Future<SavingGoalModel> getSavingGoalById(String goalId) async {
    final response = await _api.get('/saving-goals/$goalId');
    return SavingGoalModel.fromJson(response);
  }
}