import '../../utils/json_utils.dart';

class Accion {
  Accion({
    this.id,
    required this.codigo,
    required this.descripcion,
    required this.activo,
  });

  final int? id;
  final String codigo;
  final String descripcion;
  final bool activo;

  factory Accion.fromJson(Map<String, dynamic> json) {
    return Accion(
      id: parseInt(json['id'] ?? json['accionId']),
      codigo: (json['codigo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: parseBool(json['activo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'descripcion': descripcion,
      'activo': activo,
    };
  }
}
