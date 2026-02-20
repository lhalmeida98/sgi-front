import '../../utils/json_utils.dart';

class Rol {
  Rol({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.accionesIds,
    required this.activo,
    this.permisos = const [],
  });

  final int? id;
  final String nombre;
  final String descripcion;
  final List<int> accionesIds;
  final bool activo;
  final List<String> permisos;

  factory Rol.fromJson(Map<String, dynamic> json) {
    final rawPermisos = json['permisos'] ?? json['acciones'];
    final permisos = <String>[];
    final accionesIds = <int>[];
    if (rawPermisos is List) {
      for (final item in rawPermisos) {
        if (item is String) {
          permisos.add(item);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final codigo = map['codigo']?.toString();
          final nombre = map['nombre']?.toString();
          final accionId = parseInt(map['id'] ?? map['accionId']);
          if (codigo != null && codigo.isNotEmpty) {
            permisos.add(codigo);
          }
          if (nombre != null && nombre.isNotEmpty) {
            permisos.add(nombre);
          }
          if (accionId != null) {
            accionesIds.add(accionId);
          }
        }
      }
    }
    final rawAccionesIds = json['accionesIds'];
    if (rawAccionesIds is List) {
      for (final item in rawAccionesIds) {
        final accionId = parseInt(item);
        if (accionId != null) {
          accionesIds.add(accionId);
        }
      }
    }
    return Rol(
      id: parseInt(json['id'] ?? json['rolId']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      accionesIds: accionesIds,
      activo: parseBool(json['activo']) ?? true,
      permisos: permisos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'accionesIds': accionesIds,
      'activo': activo,
    };
  }
}
