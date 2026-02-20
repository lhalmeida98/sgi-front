import '../../utils/json_utils.dart';

class CobroCliente {
  CobroCliente({
    this.id,
    required this.clienteId,
    this.fechaCobro,
    required this.montoTotal,
    this.formaPago,
    this.referencia,
    this.observacion,
    this.estado,
    this.detalles = const [],
  });

  final int? id;
  final int clienteId;
  final DateTime? fechaCobro;
  final double montoTotal;
  final String? formaPago;
  final String? referencia;
  final String? observacion;
  final String? estado;
  final List<CobroClienteDetalle> detalles;

  factory CobroCliente.fromJson(Map<String, dynamic> json) {
    final rawItems = json['detalles'] ?? json['items'] ?? json['detalle'];
    return CobroCliente(
      id: parseInt(json['id'] ?? json['cobroId']),
      clienteId: parseInt(json['clienteId'] ?? json['cliente']?['id']) ?? 0,
      fechaCobro: _parseDate(json['fecha'] ?? json['fechaCobro']),
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
              .map((item) => CobroClienteDetalle.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clienteId': clienteId,
      if (fechaCobro != null) 'fecha': _formatDate(fechaCobro!),
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

class CobroClienteDetalle {
  CobroClienteDetalle({
    this.id,
    this.cuentaPorCobrarId,
    required this.montoAplicado,
  });

  final int? id;
  final int? cuentaPorCobrarId;
  final double montoAplicado;

  factory CobroClienteDetalle.fromJson(Map<String, dynamic> json) {
    return CobroClienteDetalle(
      id: parseInt(json['id'] ?? json['detalleId']),
      cuentaPorCobrarId: parseInt(
        json['cuentaPorCobrarId'] ?? json['cxcId'],
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
      if (cuentaPorCobrarId != null) 'cuentaPorCobrarId': cuentaPorCobrarId,
      'montoAplicado': montoAplicado,
    };
  }
}
