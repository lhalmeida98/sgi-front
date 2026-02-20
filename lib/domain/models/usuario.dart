import '../../utils/json_utils.dart';
import 'usuario_empresa.dart';

class Usuario {
  Usuario({
    this.id,
    required this.nombre,
    required this.usuario,
    required this.email,
    required this.roles,
    required this.empresas,
    this.telefono,
    this.autorizaCorreo,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String usuario;
  final String email;
  final List<String> roles;
  final List<UsuarioEmpresa> empresas;
  final String? telefono;
  final bool? autorizaCorreo;
  final bool activo;

  String get rolPrincipal => roles.isNotEmpty ? roles.first : '';

  UsuarioEmpresa? get empresaPrincipal {
    for (final empresa in empresas) {
      if (empresa.principal) {
        return empresa;
      }
    }
    return empresas.isNotEmpty ? empresas.first : null;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
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
    final empresas = <UsuarioEmpresa>[];
    final rawEmpresas = json['empresas'];
    if (rawEmpresas is List) {
      for (final item in rawEmpresas) {
        if (item is Map) {
          empresas.add(UsuarioEmpresa.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return Usuario(
      id: parseInt(json['id'] ?? json['usuarioId']),
      nombre: (json['nombre'] ?? '').toString(),
      usuario: (json['usuario'] ?? json['email'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      roles: roles,
      empresas: empresas,
      telefono: json['telefono']?.toString(),
      autorizaCorreo: parseBool(
        json['autorizaCorreo'] ??
            json['autorizadoCorreo'] ??
            json['correoAutorizado'],
      ),
      activo: parseBool(json['activo']) ?? false,
    );
  }

  Map<String, dynamic> toJson({String? password}) {
    return {
      'nombre': nombre,
      'usuario': usuario,
      'email': email,
      'roles': roles,
      'empresas': empresas.map((item) => item.toJson()).toList(),
      'activo': activo,
      if (password != null && password.isNotEmpty) 'password': password,
    };
  }
}
