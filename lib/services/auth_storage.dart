import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/auth_info.dart';

class AuthStoredSession {
  const AuthStoredSession({
    required this.info,
    required this.email,
  });

  final AuthInfo info;
  final String email;
}

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _tipoKey = 'auth_tipo';
  static const _rolKey = 'auth_rol';
  static const _empresaIdKey = 'auth_empresa_id';
  static const _emailKey = 'auth_email';

  static Future<void> save({
    required AuthInfo info,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, info.token);
    await prefs.setString(_tipoKey, info.tipo);
    await prefs.setString(_rolKey, info.rol);
    await prefs.setInt(_empresaIdKey, info.empresaId);
    await prefs.setString(_emailKey, email);
  }

  static Future<AuthStoredSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    final tipo = prefs.getString(_tipoKey) ?? 'Bearer';
    final rol = prefs.getString(_rolKey) ?? '';
    final empresaId = prefs.getInt(_empresaIdKey) ?? 0;
    final email = prefs.getString(_emailKey) ?? '';
    final info = AuthInfo(
      token: token,
      tipo: tipo,
      rol: rol,
      empresaId: empresaId,
    );
    return AuthStoredSession(info: info, email: email);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tipoKey);
    await prefs.remove(_rolKey);
    await prefs.remove(_empresaIdKey);
    await prefs.remove(_emailKey);
  }
}
