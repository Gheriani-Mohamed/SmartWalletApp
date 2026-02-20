import 'package:smart_wallet_app/services/ApiService.dart';
import 'package:smart_wallet_app/models/AlertModel.dart';

class AlertService {
  final ApiService _api = ApiService();

  // Get all alerts for user
  Future<List<AlertModel>> getUserAlerts(String userId) async {
    final response = await _api.get('/alerts/user/$userId');
    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

  // Get unread alerts
  Future<List<AlertModel>> getUnreadAlerts(String userId) async {
    final response = await _api.get('/alerts/user/$userId/unread');
    return (response as List)
        .map((json) => AlertModel.fromJson(json))
        .toList();
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    final response = await _api.get('/alerts/user/$userId/count');
    return response['count'] ?? 0;
  }

  // Mark alert as read
  Future<AlertModel> markAsRead(String alertId) async {
    final response = await _api.put('/alerts/$alertId/read', {});
    return AlertModel.fromJson(response);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _api.put('/alerts/user/$userId/read-all', {});
  }

  // Delete alert
  Future<void> deleteAlert(String alertId) async {
    await _api.delete('/alerts/$alertId');
  }

  // Delete all alerts
  Future<void> deleteAllAlerts(String userId) async {
    await _api.delete('/alerts/user/$userId/all');
  }
}