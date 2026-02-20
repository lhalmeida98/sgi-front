import '../domain/models/auth_info.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthInfo> login({
    required String usuarioOrEmail,
    required String password,
  }) async {
    final identifier = usuarioOrEmail.trim();
    final isEmail = identifier.contains('@');
    final payload = <String, dynamic>{
      if (isEmail) 'email': identifier,
      if (!isEmail) 'usuario': identifier,
      'password': password,
    };
    final response = await _client.post(
      '/api/auth/login',
      body: payload,
    );
    final map = extractMap(response);
    return AuthInfo.fromJson(map);
  }
}
