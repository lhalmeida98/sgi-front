import '../../utils/json_utils.dart';

class DocumentoCliente {
  DocumentoCliente({
    this.id,
    this.clienteId,
    this.tipoDocumento,
    this.numeroDocumento,
    this.numeroAutorizacion,
    this.fechaEmision,
    this.fechaVencimiento,
    this.subtotal,
    this.impuestos,
    this.total,
    this.moneda,
    this.saldo,
    this.estado,
    this.diasParaVencer,
    this.vencida,
  });

  final int? id;
  final int? clienteId;
  final String? tipoDocumento;
  final String? numeroDocumento;
  final String? numeroAutorizacion;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final double? subtotal;
  final double? impuestos;
  final double? total;
  final String? moneda;
  final double? saldo;
  final String? estado;
  final int? diasParaVencer;
  final bool? vencida;

  factory DocumentoCliente.fromJson(Map<String, dynamic> json) {
    return DocumentoCliente(
      id: parseInt(
        json['id'] ?? json['documentoClienteId'] ?? json['documentoId'],
      ),
      clienteId: parseInt(json['clienteId'] ?? json['cliente']?['id']),
      tipoDocumento: (json['tipoDocumento'] ??
              json['tipo'] ??
              json['tipoComprobante'])
          ?.toString(),
      numeroDocumento: (json['numeroDocumento'] ??
              json['numero'] ??
              json['secuencial'] ??
              json['numeroFactura'])
          ?.toString(),
      numeroAutorizacion: (json['numeroAutorizacion'] ??
              json['autorizacion'] ??
              json['claveAcceso'])
          ?.toString(),
      fechaEmision:
          _parseDate(json['fechaEmision'] ?? json['fecha'] ?? json['emision']),
      fechaVencimiento:
          _parseDate(json['fechaVencimiento'] ?? json['vencimiento']),
      subtotal: parseDouble(json['subtotal']),
      impuestos: parseDouble(json['impuestos']),
      total: parseDouble(
        json['total'] ?? json['importeTotal'] ?? json['totalDocumento'],
      ),
      moneda: json['moneda']?.toString(),
      saldo: parseDouble(json['saldo'] ?? json['saldoPendiente']),
      estado: json['estado']?.toString() ?? json['status']?.toString(),
      diasParaVencer: parseInt(json['diasParaVencer']),
      vencida: parseBool(json['vencida']),
    );
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
}
