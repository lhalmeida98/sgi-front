import '../../utils/json_utils.dart';

class Bodega {
  Bodega({
    this.id,
    this.empresaId,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.activa,
  });

  final int? id;
  final int? empresaId;
  final String nombre;
  final String descripcion;
  final String direccion;
  final bool activa;

  factory Bodega.fromJson(Map<String, dynamic> json) {
    return Bodega(
      id: parseInt(json['id'] ?? json['bodegaId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      activa: parseBool(json['activa']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'activa': activa,
    };
  }

  Bodega copyWith({
    bool? activa,
  }) {
    return Bodega(
      id: id,
      empresaId: empresaId,
      nombre: nombre,
      descripcion: descripcion,
      direccion: direccion,
      activa: activa ?? this.activa,
    );
  }
}
