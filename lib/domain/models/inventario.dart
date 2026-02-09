import '../../utils/json_utils.dart';

class Inventario {
  Inventario({
    this.id,
    this.empresaId,
    required this.productoId,
    required this.stockActual,
    required this.stockMinimo,
    required this.stockMaximo,
    required this.ubicacion,
    required this.costoPromedio,
    this.productoDescripcion,
  });

  final int? id;
  final int? empresaId;
  final int productoId;
  final int stockActual;
  final int stockMinimo;
  final int stockMaximo;
  final String ubicacion;
  final double costoPromedio;
  final String? productoDescripcion;

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: parseInt(json['id'] ?? json['inventarioId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      productoId: parseInt(json['productoId']) ?? 0,
      stockActual: parseInt(json['stockActual']) ?? 0,
      stockMinimo: parseInt(json['stockMinimo']) ?? 0,
      stockMaximo: parseInt(json['stockMaximo']) ?? 0,
      ubicacion: (json['ubicacion'] ?? '').toString(),
      costoPromedio: parseDouble(json['costoPromedio']) ?? 0,
      productoDescripcion: json['productoDescripcion']?.toString() ??
          json['producto']?['descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'productoId': productoId,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'stockMaximo': stockMaximo,
      'ubicacion': ubicacion,
      'costoPromedio': costoPromedio,
    };
  }

  bool get isLowStock => stockActual <= stockMinimo;
}
