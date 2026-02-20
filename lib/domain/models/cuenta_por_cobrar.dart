import '../../utils/json_utils.dart';

class CuentaPorCobrar {
  CuentaPorCobrar({
    this.id,
    this.clienteId,
    this.documentoId,
    this.documentoClienteId,
    this.numeroDocumento,
    this.documentoNumero,
    this.documentoTipo,
    this.tipoDocumento,
    this.fechaEmision,
    this.fechaVencimiento,
    this.total,
    this.montoOriginal,
    this.montoCobrado,
    this.saldo,
    this.estado,
    this.creditoDias,
    this.creditoBucket,
    this.diasParaVencer,
    this.vencida,
    this.bucketVencimiento,
  });

  final int? id;
  final int? clienteId;
  final int? documentoId;
  final int? documentoClienteId;
  final String? numeroDocumento;
  final String? documentoNumero;
  final String? documentoTipo;
  final String? tipoDocumento;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final double? total;
  final double? montoOriginal;
  final double? montoCobrado;
  final double? saldo;
  final String? estado;
  final int? creditoDias;
  final String? creditoBucket;
  final int? diasParaVencer;
  final bool? vencida;
  final String? bucketVencimiento;

  factory CuentaPorCobrar.fromJson(Map<String, dynamic> json) {
    final documentoClienteId =
        parseInt(json['documentoClienteId'] ?? json['documentoId']);
    final documentoNumero = (json['documentoNumero'] ??
            json['numeroDocumento'] ??
            json['numeroFactura'] ??
            json['numero'] ??
            json['secuencial'])
        ?.toString();
    final montoOriginal = parseDouble(
      json['montoOriginal'] ?? json['total'] ?? json['importeTotal'],
    );
    final montoCobrado =
        parseDouble(json['montoCobrado'] ?? json['montoPagado'] ?? json['pagado']);
    return CuentaPorCobrar(
      id: parseInt(json['id'] ?? json['cxcId']),
      clienteId: parseInt(json['clienteId'] ?? json['cliente']?['id']),
      documentoId: documentoClienteId,
      documentoClienteId: documentoClienteId,
      numeroDocumento: documentoNumero,
      documentoNumero: documentoNumero,
      documentoTipo: json['documentoTipo']?.toString(),
      tipoDocumento:
          json['tipoDocumento']?.toString() ?? json['tipo']?.toString(),
      fechaEmision:
          _parseDate(json['fechaEmision'] ?? json['fecha'] ?? json['emision']),
      fechaVencimiento:
          _parseDate(json['fechaVencimiento'] ?? json['vencimiento']),
      total: montoOriginal,
      montoOriginal: montoOriginal,
      montoCobrado: montoCobrado,
      saldo: parseDouble(json['saldo'] ?? json['saldoPendiente']),
      estado: json['estado']?.toString() ?? json['status']?.toString(),
      creditoDias: parseInt(json['creditoDias'] ?? json['diasCredito']),
      creditoBucket: json['creditoBucket']?.toString(),
      diasParaVencer: parseInt(json['diasParaVencer']),
      vencida: parseBool(json['vencida']),
      bucketVencimiento: json['bucketVencimiento']?.toString(),
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
