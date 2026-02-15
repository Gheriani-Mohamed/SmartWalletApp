import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';

class AlertService {
  final ApiService _api = ApiService();

  // Get all alerts for a user
  Future<List<Alert>> getUserAlerts(String userId) async {
    final response = await _api.get('/alerts/user/$userId');
    if (response is List) {
      return response
          .map((json) => Alert.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get unread alerts only
  Future<List<Alert>> getUnreadAlerts(String userId) async {
    final response = await _api.get('/alerts/unread/$userId');
    if (response is List) {
      return response
          .map((json) => Alert.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  // Get unread alert count (for badge)
  Future<int> getUnreadCount(String userId) async {
    final response = await _api.get('/alerts/count/$userId');
    if (response is Map<String, dynamic>) {
      return response['count'] as int? ?? 0;
    }
    return 0;
  }
}
