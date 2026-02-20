import '../../utils/json_utils.dart';
import 'menu_accion.dart';

class AuthInfo {
  AuthInfo({
    required this.token,
    required this.tipo,
    required this.roles,
    required this.acciones,
    required this.empresaId,
    this.usuarioId,
  });

  final String token;
  final String tipo;
  final List<String> roles;
  final List<MenuAccion> acciones;
  final int empresaId;
  final int? usuarioId;

  bool get isAdmin => roles.any((rol) => rol.toUpperCase() == 'ADMIN');

  String get rolPrincipal => roles.isNotEmpty ? roles.first : '';

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    final roles = <String>[];
    final rawRoles = json['roles'] ?? json['rol'];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        if (item is String) {
          roles.add(item);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final nombre = map['nombre']?.toString() ?? map['codigo']?.toString();
          if (nombre != null && nombre.isNotEmpty) {
            roles.add(nombre);
          }
        }
      }
    } else if (rawRoles != null) {
      roles.add(rawRoles.toString());
    }
    if (roles.isEmpty && json['rol'] != null) {
      roles.add(json['rol'].toString());
    }
    final rawAcciones = json['acciones'];
    final acciones = extractList(rawAcciones)
        .map(MenuAccion.fromJson)
        .where((accion) => accion.nombre.isNotEmpty)
        .toList();
    return AuthInfo(
      token: (json['token'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'Bearer').toString(),
      roles: roles,
      acciones: acciones,
      empresaId: parseInt(json['empresaId']) ?? 0,
      usuarioId: parseInt(json['usuarioId'] ?? json['id'] ?? json['userId']),
    );
  }
}
