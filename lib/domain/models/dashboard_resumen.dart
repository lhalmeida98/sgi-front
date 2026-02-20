import '../../utils/json_utils.dart';

class DashboardResumen {
  DashboardResumen({
    this.ventasMes,
    this.ventasMesAnterior,
    this.ventasVariacionPct,
    this.cuentasPorCobrarTotal,
    this.cuentasPorCobrarPendientesHoy,
    this.stockCritico,
    this.proveedoresPorPagarTotal,
    this.proveedoresPorPagarVencenSemana,
    this.flujoCaja30Dias = const [],
    this.ultimasFacturas = const [],
    this.productosMasVendidos = const [],
    this.productosMenosStock = const [],
  });

  final double? ventasMes;
  final double? ventasMesAnterior;
  final double? ventasVariacionPct;
  final double? cuentasPorCobrarTotal;
  final int? cuentasPorCobrarPendientesHoy;
  final int? stockCritico;
  final double? proveedoresPorPagarTotal;
  final int? proveedoresPorPagarVencenSemana;
  final List<DashboardCashflowItem> flujoCaja30Dias;
  final List<DashboardFacturaItem> ultimasFacturas;
  final List<DashboardProductoVentaItem> productosMasVendidos;
  final List<DashboardProductoStockItem> productosMenosStock;

  factory DashboardResumen.fromJson(Map<String, dynamic> json) {
    final rawCashflow = json['flujoCaja30Dias'] ??
        json['flujoCaja'] ??
        json['cashflow'];
    final rawFacturas = json['ultimasFacturas'] ?? json['facturas'];
    final rawTop = json['productosMasVendidos'] ?? json['topProductos'];
    final rawLow = json['productosMenosStock'] ?? json['stockCriticoDetalle'];

    return DashboardResumen(
      ventasMes: parseDouble(json['ventasMes']),
      ventasMesAnterior: parseDouble(json['ventasMesAnterior']),
      ventasVariacionPct: parseDouble(json['ventasVariacionPct']),
      cuentasPorCobrarTotal: parseDouble(json['cuentasPorCobrarTotal']),
      cuentasPorCobrarPendientesHoy:
          parseInt(json['cuentasPorCobrarPendientesHoy']),
      stockCritico: parseInt(json['stockCritico']),
      proveedoresPorPagarTotal: parseDouble(json['proveedoresPorPagarTotal']),
      proveedoresPorPagarVencenSemana:
          parseInt(json['proveedoresPorPagarVencenSemana']),
      flujoCaja30Dias: _parseList(
        rawCashflow,
        (item) => DashboardCashflowItem.fromJson(item),
      ),
      ultimasFacturas: _parseList(
        rawFacturas,
        (item) => DashboardFacturaItem.fromJson(item),
      ),
      productosMasVendidos: _parseList(
        rawTop,
        (item) => DashboardProductoVentaItem.fromJson(item),
      ),
      productosMenosStock: _parseList(
        rawLow,
        (item) => DashboardProductoStockItem.fromJson(item),
      ),
    );
  }

  static List<T> _parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return const [];
  }
}

class DashboardCashflowItem {
  DashboardCashflowItem({
    this.fecha,
    this.ingresos,
    this.egresos,
    this.neto,
  });

  final DateTime? fecha;
  final double? ingresos;
  final double? egresos;
  final double? neto;

  factory DashboardCashflowItem.fromJson(Map<String, dynamic> json) {
    final ingresos = parseDouble(json['ingresos'] ?? json['entrada']);
    final egresos = parseDouble(json['egresos'] ?? json['salida']);
    return DashboardCashflowItem(
      fecha: _parseDate(json['fecha'] ?? json['dia'] ?? json['date']),
      ingresos: ingresos,
      egresos: egresos,
      neto: parseDouble(json['neto']) ??
          ((ingresos != null && egresos != null) ? ingresos - egresos : null),
    );
  }
}

class DashboardFacturaItem {
  DashboardFacturaItem({
    this.numero,
    this.total,
    this.estado,
  });

  final String? numero;
  final double? total;
  final String? estado;

  factory DashboardFacturaItem.fromJson(Map<String, dynamic> json) {
    return DashboardFacturaItem(
      numero: (json['numero'] ??
              json['numeroFactura'] ??
              json['secuencial'] ??
              json['documento'])
          ?.toString(),
      total: parseDouble(
        json['total'] ?? json['totalFactura'] ?? json['importeTotal'],
      ),
      estado: json['estado']?.toString() ?? json['status']?.toString(),
    );
  }
}

class DashboardProductoVentaItem {
  DashboardProductoVentaItem({
    this.productoId,
    this.descripcion,
    this.cantidad,
    this.total,
  });

  final int? productoId;
  final String? descripcion;
  final double? cantidad;
  final double? total;

  factory DashboardProductoVentaItem.fromJson(Map<String, dynamic> json) {
    return DashboardProductoVentaItem(
      productoId: parseInt(json['productoId'] ?? json['id']),
      descripcion:
          (json['descripcion'] ?? json['producto'] ?? json['nombre'])
              ?.toString(),
      cantidad: parseDouble(json['cantidad'] ?? json['unidades']),
      total: parseDouble(json['total'] ?? json['monto']),
    );
  }
}

class DashboardProductoStockItem {
  DashboardProductoStockItem({
    this.productoId,
    this.descripcion,
    this.stockActual,
    this.stockMinimo,
  });

  final int? productoId;
  final String? descripcion;
  final double? stockActual;
  final double? stockMinimo;

  factory DashboardProductoStockItem.fromJson(Map<String, dynamic> json) {
    return DashboardProductoStockItem(
      productoId: parseInt(json['productoId'] ?? json['id']),
      descripcion:
          (json['descripcion'] ?? json['producto'] ?? json['nombre'])
              ?.toString(),
      stockActual: parseDouble(json['stockActual'] ?? json['stock']),
      stockMinimo: parseDouble(json['stockMinimo'] ?? json['stockMinimo']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
