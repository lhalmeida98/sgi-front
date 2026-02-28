import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/auth_info.dart';
import '../domain/models/menu_accion.dart';

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
  static const _rolesKey = 'auth_roles';
  static const _accionesKey = 'auth_acciones';
  static const _rolKeyLegacy = 'auth_rol';
  static const _empresaIdKey = 'auth_empresa_id';
  static const _usuarioIdKey = 'auth_usuario_id';
  static const _emailKey = 'auth_email';
  static const _rememberedIdentifierKey = 'auth_remembered_identifier';

  static Future<void> save({
    required AuthInfo info,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, info.token);
    await prefs.setString(_tipoKey, info.tipo);
    await prefs.setStringList(_rolesKey, info.roles);
    final accionesPayload =
        jsonEncode(info.acciones.map((accion) => accion.toJson()).toList());
    await prefs.setString(_accionesKey, accionesPayload);
    await prefs.setInt(_empresaIdKey, info.empresaId);
    if (info.usuarioId != null) {
      await prefs.setInt(_usuarioIdKey, info.usuarioId!);
    } else {
      await prefs.remove(_usuarioIdKey);
    }
    await prefs.setString(_emailKey, email);
  }

  static Future<AuthStoredSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    final tipo = prefs.getString(_tipoKey) ?? 'Bearer';
    final roles = prefs.getStringList(_rolesKey) ?? [];
    if (roles.isEmpty) {
      final legacyRol = prefs.getString(_rolKeyLegacy);
      if (legacyRol != null && legacyRol.trim().isNotEmpty) {
        roles.add(legacyRol);
      }
    }
    final accionesRaw = prefs.getString(_accionesKey) ?? '[]';
    final accionesList = _decodeAcciones(accionesRaw);
    final empresaId = prefs.getInt(_empresaIdKey) ?? 0;
    final usuarioId = prefs.getInt(_usuarioIdKey);
    final email = prefs.getString(_emailKey) ?? '';
    final info = AuthInfo(
      token: token,
      tipo: tipo,
      roles: roles,
      acciones: accionesList,
      empresaId: empresaId,
      usuarioId: usuarioId,
    );
    return AuthStoredSession(info: info, email: email);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tipoKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_accionesKey);
    await prefs.remove(_rolKeyLegacy);
    await prefs.remove(_empresaIdKey);
    await prefs.remove(_usuarioIdKey);
    await prefs.remove(_emailKey);
  }

  static Future<String?> readRememberedIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_rememberedIdentifierKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static Future<void> saveRememberedIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedIdentifierKey, identifier.trim());
  }

  static Future<void> clearRememberedIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedIdentifierKey);
  }

  static List<MenuAccion> _decodeAcciones(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => MenuAccion.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
