import '../../utils/json_utils.dart';

class Inventario {
  Inventario({
    this.id,
    this.empresaId,
    required this.productoId,
    this.productoNombre,
    this.bodegaId,
    this.bodegaNombre,
    required this.stockActual,
    this.stockReservado,
    required this.stockMinimo,
    required this.stockMaximo,
    required this.ubicacion,
    required this.costoPromedio,
    this.precioVenta,
    this.margenPorcentaje,
    this.stockGlobal,
    this.stockReservadoGlobal,
    this.costoPromedioGlobal,
    this.margenPorcentajeGlobal,
    this.productoDescripcion,
  });

  final int? id;
  final int? empresaId;
  final int productoId;
  final String? productoNombre;
  final int? bodegaId;
  final String? bodegaNombre;
  final int stockActual;
  final int? stockReservado;
  final int stockMinimo;
  final int stockMaximo;
  final String ubicacion;
  final double costoPromedio;
  final double? precioVenta;
  final double? margenPorcentaje;
  final int? stockGlobal;
  final int? stockReservadoGlobal;
  final double? costoPromedioGlobal;
  final double? margenPorcentajeGlobal;
  final String? productoDescripcion;

  factory Inventario.fromJson(Map<String, dynamic> json) {
    return Inventario(
      id: parseInt(json['id'] ?? json['inventarioId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      productoId: parseInt(json['productoId']) ?? 0,
      productoNombre: json['productoNombre']?.toString() ??
          json['producto']?['descripcion']?.toString(),
      bodegaId: parseInt(json['bodegaId']),
      bodegaNombre:
          json['bodegaNombre']?.toString() ?? json['bodega']?['nombre']?.toString(),
      stockActual: parseInt(json['stockActual']) ?? 0,
      stockReservado: parseInt(json['stockReservado']),
      stockMinimo: parseInt(json['stockMinimo']) ?? 0,
      stockMaximo: parseInt(json['stockMaximo']) ?? 0,
      ubicacion: (json['ubicacion'] ?? '').toString(),
      costoPromedio: parseDouble(json['costoPromedio']) ?? 0,
      precioVenta: parseDouble(json['precioVenta']),
      margenPorcentaje: parseDouble(json['margenPorcentaje']),
      stockGlobal: parseInt(json['stockGlobal']),
      stockReservadoGlobal: parseInt(json['stockReservadoGlobal']),
      costoPromedioGlobal: parseDouble(json['costoPromedioGlobal']),
      margenPorcentajeGlobal: parseDouble(json['margenPorcentajeGlobal']),
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
