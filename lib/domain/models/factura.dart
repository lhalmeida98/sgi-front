import '../../utils/json_utils.dart';

class Factura {
  Factura({
    this.id,
    this.numero,
    this.cliente,
    this.fechaEmision,
    this.total,
    this.estado,
    this.mensaje,
    this.sriEstadoConsulta,
    this.sriEstadoAutorizacion,
    this.sriMensaje,
    this.claveAcceso,
  });

  final int? id;
  final String? numero;
  final String? cliente;
  final DateTime? fechaEmision;
  final double? total;
  final String? estado;
  final String? mensaje;
  final String? sriEstadoConsulta;
  final String? sriEstadoAutorizacion;
  final String? sriMensaje;
  final String? claveAcceso;

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: parseInt(json['id'] ?? json['facturaId']),
      numero: json['numero']?.toString() ??
          json['numeroFactura']?.toString() ??
          json['secuencial']?.toString(),
      cliente: _extractCliente(json),
      fechaEmision: _parseDate(json['fechaEmision'] ?? json['fecha']),
      total: parseDouble(
        json['total'] ?? json['totalFactura'] ?? json['importeTotal'],
      ),
      estado: json['estado']?.toString(),
      mensaje: json['mensaje']?.toString() ?? json['detalle']?.toString(),
      sriEstadoConsulta:
          (json['sriEstado']?['estadoConsulta'] ?? json['estadoConsulta'])
              ?.toString(),
      sriEstadoAutorizacion:
          (json['sriEstado']?['estadoAutorizacion'] ?? json['estadoAutorizacion'])
              ?.toString(),
      sriMensaje:
          (json['sriEstado']?['mensaje'] ?? json['mensajeSri'])?.toString(),
      claveAcceso: json['claveAcceso']?.toString(),
    );
  }

  static String? _extractCliente(Map<String, dynamic> json) {
    final direct =
        json['clienteRazonSocial'] ?? json['clienteNombre'] ?? json['cliente'];
    if (direct is String) {
      return direct;
    }
    if (direct is Map) {
      final razon = direct['razonSocial'] ?? direct['nombre'];
      if (razon != null) {
        return razon.toString();
      }
    }
    final nested = json['cliente']?['razonSocial'] ?? json['cliente']?['nombre'];
    return nested?.toString();
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
