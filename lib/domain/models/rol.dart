import '../../utils/json_utils.dart';

class Rol {
  Rol({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.permisos,
  });

  final int? id;
  final String nombre;
  final String descripcion;
  final List<String> permisos;

  factory Rol.fromJson(Map<String, dynamic> json) {
    final rawPermisos = json['permisos'] ?? json['acciones'];
    final permisos = <String>[];
    if (rawPermisos is List) {
      for (final item in rawPermisos) {
        if (item is String) {
          permisos.add(item);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final codigo = map['codigo']?.toString();
          if (codigo != null && codigo.isNotEmpty) {
            permisos.add(codigo);
          }
        }
      }
    }
    return Rol(
      id: parseInt(json['id'] ?? json['rolId']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      permisos: permisos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'permisos': permisos,
    };
  }
}
