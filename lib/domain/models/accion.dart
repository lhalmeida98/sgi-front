import '../../utils/json_utils.dart';

class Accion {
  Accion({
    this.id,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.url,
    required this.icono,
    required this.tipo,
    required this.activo,
  });

  final int? id;
  final String nombre;
  final String codigo;
  final String descripcion;
  final String url;
  final String icono;
  final String tipo;
  final bool activo;

  factory Accion.fromJson(Map<String, dynamic> json) {
    final codigo = (json['codigo'] ?? '').toString();
    final nombre = (json['nombre'] ?? '').toString();
    return Accion(
      id: parseInt(json['id'] ?? json['accionId']),
      nombre: nombre.isNotEmpty ? nombre : codigo,
      codigo: codigo,
      descripcion: (json['descripcion'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      icono: (json['icono'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      activo: parseBool(json['activo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'url': url,
      'icono': icono,
      'tipo': tipo,
      'activo': activo,
    };
  }
}
