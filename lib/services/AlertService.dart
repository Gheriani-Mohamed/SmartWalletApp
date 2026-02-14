import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';

class AlertService {
  final ApiService _api = ApiService();

  // Get all alerts for a user
  Future<List<AlertModel>> getUserAlerts(String userId) async {
    final response = await _api.get('/alerts/user/$userId');
    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

  // Get unread alerts only
  Future<List<AlertModel>> getUnreadAlerts(String userId) async {
    final response = await _api.get('/alerts/unread/$userId');
    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

  // Get unread alert count (for badge)
  Future<int> getUnreadCount(String userId) async {
    final response = await _api.get('/alerts/count/$userId');
    return response['count'] ?? 0;
  }
}