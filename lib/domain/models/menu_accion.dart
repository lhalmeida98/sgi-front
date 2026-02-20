import '../../utils/json_utils.dart';

class MenuAccion {
  MenuAccion({
    required this.nombre,
    required this.descripcion,
    required this.url,
    required this.icono,
    required this.tipo,
    this.activo,
  });

  final String nombre;
  final String descripcion;
  final String url;
  final String icono;
  final String tipo;
  final bool? activo;

  factory MenuAccion.fromJson(Map<String, dynamic> json) {
    return MenuAccion(
      nombre: (json['nombre'] ?? json['codigo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      icono: (json['icono'] ?? '').toString(),
      tipo: (json['tipo'] ?? json['grupo'] ?? '').toString(),
      activo: parseBool(json['activo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'url': url,
      'icono': icono,
      'tipo': tipo,
      if (activo != null) 'activo': activo,
    };
  }
}
