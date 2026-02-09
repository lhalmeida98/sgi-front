import '../../utils/json_utils.dart';

class Usuario {
  Usuario({
    this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: parseInt(json['id'] ?? json['usuarioId']),
      nombre: (json['nombre'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      activo: parseBool(json['activo']) ?? false,
    );
  }

  Map<String, dynamic> toJson({String? password}) {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'activo': activo,
      if (password != null && password.isNotEmpty) 'password': password,
    };
  }
}
