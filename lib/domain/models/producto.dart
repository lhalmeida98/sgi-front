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
    this.vendible = true,
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
  final bool vendible;

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
      vendible: parseBool(json['vendible']) ?? true,
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
      'vendible': vendible,
    };
  }

  Producto copyWith({
    int? id,
    int? empresaId,
    String? codigo,
    String? codigoBarras,
    String? descripcion,
    double? precioUnitario,
    int? categoriaId,
    int? impuestoId,
    String? categoriaNombre,
    String? impuestoDescripcion,
    bool? vendible,
  }) {
    return Producto(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      codigo: codigo ?? this.codigo,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      descripcion: descripcion ?? this.descripcion,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      categoriaId: categoriaId ?? this.categoriaId,
      impuestoId: impuestoId ?? this.impuestoId,
      categoriaNombre: categoriaNombre ?? this.categoriaNombre,
      impuestoDescripcion: impuestoDescripcion ?? this.impuestoDescripcion,
      vendible: vendible ?? this.vendible,
    );
  }
}
