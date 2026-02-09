import '../../utils/json_utils.dart';

class Categoria {
  Categoria({
    this.id,
    this.empresaId,
    this.empresaNombre,
    required this.nombre,
    required this.descripcion,
  });

  final int? id;
  final int? empresaId;
  final String? empresaNombre;
  final String nombre;
  final String descripcion;

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: parseInt(json['id'] ?? json['categoriaId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      empresaNombre: json['empresaNombre']?.toString() ??
          json['empresa']?['razonSocial']?.toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (empresaId != null) 'empresaId': empresaId,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
