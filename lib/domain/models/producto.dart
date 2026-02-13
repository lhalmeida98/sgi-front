import '../../utils/json_utils.dart';

class Producto {
  Producto({
    this.id,
    this.empresaId,
    required this.codigo,
    this.codigoBarras,
    required this.descripcion,
    required this.precioUnitario,
    required this.categoriaId,
    required this.impuestoId,
    this.categoriaNombre,
    this.impuestoDescripcion,
  });

  final int? id;
  final int? empresaId;
  final String codigo;
  final String? codigoBarras;
  final String descripcion;
  final double precioUnitario;
  final int categoriaId;
  final int impuestoId;
  final String? categoriaNombre;
  final String? impuestoDescripcion;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: parseInt(json['id'] ?? json['productoId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      codigo: (json['codigo'] ?? '').toString(),
      codigoBarras: json['codigoBarras']?.toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioUnitario: parseDouble(json['precioUnitario']) ?? 0,
      categoriaId: parseInt(json['categoriaId']) ?? 0,
      impuestoId: parseInt(json['impuestoId']) ?? 0,
      categoriaNombre: json['categoriaNombre']?.toString() ??
          json['categoria']?['nombre']?.toString(),
      impuestoDescripcion: json['impuestoDescripcion']?.toString() ??
          json['impuesto']?['descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      if (codigoBarras != null && codigoBarras!.isNotEmpty)
        'codigoBarras': codigoBarras,
      'descripcion': descripcion,
      'precioUnitario': precioUnitario,
      'categoriaId': categoriaId,
      'impuestoId': impuestoId,
    };
  }
}
