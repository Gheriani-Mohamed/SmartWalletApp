import 'ApiService.dart';

class WalletMembersService {
  final ApiService _api = ApiService();

  Future<void> addMember(String walletId, String email) async {
    await _api.post('/walletsMember/$walletId/members', {
      'userEmail': email,
    });
  }

  // Get members of a wallet
  Future<List<Map<String, dynamic>>> getMembers(String walletId) async {
    final response = await _api.get('/walletsMember/$walletId/members');

    // _api.get should return decoded JSON (Map or List), otherwise decode manually
    if (response is List) {
      return response.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch wallet members');
    }
  }
  Future<void> removeMember(String walletId, String userId) async {
    await _api.delete('/walletsMember/$walletId/members/$userId');
  }

}