import '../../utils/json_utils.dart';

class InventarioProductoDisponible {
  InventarioProductoDisponible({
    required this.productoId,
    required this.codigo,
    required this.descripcion,
    required this.precioUnitario,
    required this.categoriaId,
    required this.impuestoId,
    this.codigoBarras,
    required this.bodegaId,
    required this.bodegaNombre,
    required this.stockActual,
    this.stockReservado,
    required this.stockDisponible,
    required this.stockMinimo,
    required this.stockMaximo,
    required this.ubicacion,
    required this.costoPromedio,
  });

  final int productoId;
  final String codigo;
  final String descripcion;
  final double precioUnitario;
  final int categoriaId;
  final int impuestoId;
  final String? codigoBarras;
  final int bodegaId;
  final String bodegaNombre;
  final double stockActual;
  final double? stockReservado;
  final double stockDisponible;
  final double stockMinimo;
  final double stockMaximo;
  final String ubicacion;
  final double costoPromedio;

  factory InventarioProductoDisponible.fromJson(Map<String, dynamic> json) {
    return InventarioProductoDisponible(
      productoId: parseInt(json['productoId']) ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioUnitario: parseDouble(json['precioUnitario']) ?? 0,
      categoriaId: parseInt(json['categoriaId']) ?? 0,
      impuestoId: parseInt(json['impuestoId']) ?? 0,
      codigoBarras: json['codigoBarras']?.toString(),
      bodegaId: parseInt(json['bodegaId']) ?? 0,
      bodegaNombre: (json['bodegaNombre'] ?? '').toString(),
      stockActual: parseDouble(json['stockActual']) ?? 0,
      stockReservado: parseDouble(json['stockReservado']),
      stockDisponible: parseDouble(json['stockDisponible']) ?? 0,
      stockMinimo: parseDouble(json['stockMinimo']) ?? 0,
      stockMaximo: parseDouble(json['stockMaximo']) ?? 0,
      ubicacion: (json['ubicacion'] ?? '').toString(),
      costoPromedio: parseDouble(json['costoPromedio']) ?? 0,
    );
  }
}
