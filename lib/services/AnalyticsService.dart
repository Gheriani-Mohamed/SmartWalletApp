import 'package:smart_wallet_app/services/ApiService.dart';

class AnalyticsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getSpendingByCategory(String walletId, String period) async {
    final response = await _api.get('/analytics/category?walletId=$walletId&period=$period');
    return response;
  }

  Future<Map<String, dynamic>> getIncomeVsExpense(String walletId, String period) async {
    final response = await _api.get('/analytics/income-expense?walletId=$walletId&period=$period');
    return response;
  }

  Future<Map<String, dynamic>> getSummary(String walletId, String period) async {
    final response = await _api.get('/analytics/summary?walletId=$walletId&period=$period');
    return response;
  }
}