import '../../utils/json_utils.dart';

class PagoProveedor {
  PagoProveedor({
    this.id,
    required this.proveedorId,
    this.fechaPago,
    required this.montoTotal,
    this.formaPago,
    this.referencia,
    this.observacion,
    this.estado,
    this.detalles = const [],
  });

  final int? id;
  final int proveedorId;
  final DateTime? fechaPago;
  final double montoTotal;
  final String? formaPago;
  final String? referencia;
  final String? observacion;
  final String? estado;
  final List<PagoProveedorDetalle> detalles;

  factory PagoProveedor.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] ?? json['items'] ?? json['detalle'];
    return PagoProveedor(
      id: parseInt(json['id'] ?? json['pagoId']),
      proveedorId: parseInt(json['proveedorId'] ?? json['proveedor']?['id']) ??
          0,
      fechaPago: _parseDate(json['fecha'] ?? json['fechaPago']),
      montoTotal: parseDouble(json['total'] ?? json['montoTotal']) ?? 0,
      formaPago: json['formaPago']?.toString() ??
          json['metodo']?.toString() ??
          json['tipoPago']?.toString(),
      referencia: json['referencia']?.toString() ??
          json['numero']?.toString() ??
          json['comprobante']?.toString(),
      observacion: json['observacion']?.toString(),
      estado: json['estado']?.toString(),
      detalles: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => PagoProveedorDetalle.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'proveedorId': proveedorId,
      if (fechaPago != null) 'fechaPago': _formatDate(fechaPago!),
      'montoTotal': montoTotal,
      if (formaPago != null && formaPago!.isNotEmpty) 'formaPago': formaPago,
      if (referencia != null && referencia!.isNotEmpty) 'referencia': referencia,
      if (observacion != null && observacion!.isNotEmpty)
        'observacion': observacion,
      if (detalles.isNotEmpty)
        'detalles': detalles.map((item) => item.toJson()).toList(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class PagoProveedorDetalle {
  PagoProveedorDetalle({
    this.id,
    this.cuentaPorPagarId,
    required this.montoAplicado,
  });

  final int? id;
  final int? cuentaPorPagarId;
  final double montoAplicado;

  factory PagoProveedorDetalle.fromJson(Map<String, dynamic> json) {
    return PagoProveedorDetalle(
      id: parseInt(json['id'] ?? json['detalleId']),
      cuentaPorPagarId: parseInt(
        json['cuentaPorPagarId'] ?? json['cxpId'],
      ),
      montoAplicado: parseDouble(
            json['montoAplicado'] ?? json['monto'] ?? json['valor'],
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (cuentaPorPagarId != null) 'cuentaPorPagarId': cuentaPorPagarId,
      'montoAplicado': montoAplicado,
    };
  }
}
