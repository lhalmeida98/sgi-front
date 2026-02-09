import '../domain/models/auth_info.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthInfo> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    final map = extractMap(response);
    return AuthInfo.fromJson(map);
  }
}
