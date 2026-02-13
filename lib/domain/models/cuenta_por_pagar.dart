import '../../utils/json_utils.dart';

class CuentaPorPagar {
  CuentaPorPagar({
    this.id,
    this.proveedorId,
    this.documentoId,
    this.documentoProveedorId,
    this.numeroDocumento,
    this.documentoNumero,
    this.documentoTipo,
    this.tipoDocumento,
    this.fechaEmision,
    this.fechaVencimiento,
    this.total,
    this.montoOriginal,
    this.montoPagado,
    this.saldo,
    this.estado,
  });

  final int? id;
  final int? proveedorId;
  final int? documentoId;
  final int? documentoProveedorId;
  final String? numeroDocumento;
  final String? documentoNumero;
  final String? documentoTipo;
  final String? tipoDocumento;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final double? total;
  final double? montoOriginal;
  final double? montoPagado;
  final double? saldo;
  final String? estado;

  factory CuentaPorPagar.fromJson(Map<String, dynamic> json) {
    final documentoProveedorId =
        parseInt(json['documentoProveedorId'] ?? json['documentoId']);
    final documentoNumero = (json['documentoNumero'] ??
            json['numeroDocumento'] ??
            json['numero'] ??
            json['secuencial'])
        ?.toString();
    final montoOriginal = parseDouble(
      json['montoOriginal'] ?? json['total'] ?? json['importeTotal'],
    );
    final montoPagado = parseDouble(json['montoPagado'] ?? json['pagado']);
    return CuentaPorPagar(
      id: parseInt(json['id'] ?? json['cxpId']),
      proveedorId: parseInt(json['proveedorId'] ?? json['proveedor']?['id']),
      documentoId: documentoProveedorId,
      documentoProveedorId: documentoProveedorId,
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
      montoPagado: montoPagado,
      saldo: parseDouble(json['saldo'] ?? json['saldoPendiente']),
      estado: json['estado']?.toString() ?? json['status']?.toString(),
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
