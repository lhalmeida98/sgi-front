import '../../utils/json_utils.dart';

class Factura {
  Factura({
    this.id,
    this.numero,
    this.cliente,
    this.ambiente,
    this.fechaEmision,
    this.total,
    this.totalSinImpuestos,
    this.totalImpuestos,
    this.estado,
    this.mensaje,
    this.sriEstadoConsulta,
    this.sriEstadoAutorizacion,
    this.sriMensaje,
    this.claveAcceso,
    this.numeroAutorizacion,
    this.fechaAutorizacion,
    this.pagos = const [],
  });

  final int? id;
  final String? numero;
  final String? cliente;
  final String? ambiente;
  final DateTime? fechaEmision;
  final double? total;
  final double? totalSinImpuestos;
  final double? totalImpuestos;
  final String? estado;
  final String? mensaje;
  final String? sriEstadoConsulta;
  final String? sriEstadoAutorizacion;
  final String? sriMensaje;
  final String? claveAcceso;
  final String? numeroAutorizacion;
  final DateTime? fechaAutorizacion;
  final List<FacturaPagoResumen> pagos;

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: parseInt(json['id'] ?? json['facturaId']),
      numero: json['numero']?.toString() ??
          json['numeroFactura']?.toString() ??
          json['secuencial']?.toString(),
      cliente: _extractCliente(json),
      ambiente: _extractAmbiente(json),
      fechaEmision: _parseDate(json['fechaEmision'] ?? json['fecha']),
      total: parseDouble(
        json['total'] ?? json['totalFactura'] ?? json['importeTotal'],
      ),
      totalSinImpuestos: parseDouble(json['totalSinImpuestos']),
      totalImpuestos: parseDouble(json['totalImpuestos']),
      estado: json['estado']?.toString(),
      mensaje: json['mensaje']?.toString() ?? json['detalle']?.toString(),
      sriEstadoConsulta:
          (json['sriEstado']?['estadoConsulta'] ?? json['estadoConsulta'])
              ?.toString(),
      sriEstadoAutorizacion: (json['sriEstado']?['estadoAutorizacion'] ??
              json['estadoAutorizacion'])
          ?.toString(),
      sriMensaje:
          (json['sriEstado']?['mensaje'] ?? json['mensajeSri'])?.toString(),
      claveAcceso: json['claveAcceso']?.toString(),
      numeroAutorizacion: json['numeroAutorizacion']?.toString(),
      fechaAutorizacion: _parseDate(json['fechaAutorizacion']),
      pagos: _extractPagos(json),
    );
  }

  bool get esProduccion {
    final normalized = ambiente?.trim().toUpperCase();
    return normalized == '2' || normalized == 'PRODUCCION';
  }

  bool get esCredito {
    return pagos.any((pago) => pago.esCredito);
  }

  double get montoTotal => total ?? 0;

  double get ivaTotal => totalImpuestos ?? 0;

  double get montoCredito {
    if (pagos.isEmpty) {
      return esCredito ? montoTotal : 0;
    }
    return pagos
        .where((pago) => pago.esCredito)
        .fold<double>(0, (sum, pago) => sum + pago.monto);
  }

  double get montoCobrado {
    if (pagos.isEmpty) {
      return esCredito ? 0 : montoTotal;
    }
    return pagos
        .where((pago) => !pago.esCredito)
        .fold<double>(0, (sum, pago) => sum + pago.monto);
  }

  double ivaProporcional(double monto) {
    final base = montoTotal;
    if (base <= 0 || monto <= 0) {
      return 0;
    }
    return ivaTotal * (monto / base);
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
    final nested =
        json['cliente']?['razonSocial'] ?? json['cliente']?['nombre'];
    return nested?.toString();
  }

  static List<FacturaPagoResumen> _extractPagos(Map<String, dynamic> json) {
    final raw = json['pagos'];
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => FacturaPagoResumen.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static String? _extractAmbiente(Map<String, dynamic> json) {
    final direct = json['ambiente'] ??
        json['infoAmbiente'] ??
        json['info_ambiente'] ??
        json['infoTributaria']?['ambiente'] ??
        json['infoTributaria']?['infoAmbiente'] ??
        json['infoTributaria']?['info_ambiente'];
    final directValue = direct?.toString().trim();
    if (directValue != null && directValue.isNotEmpty) {
      return directValue;
    }
    final clave = (json['claveAcceso'] ??
            json['clave_acceso'] ??
            json['numeroAutorizacion'] ??
            json['numero_autorizacion'])
        ?.toString()
        .trim();
    if (clave == null || clave.length < 24) {
      return null;
    }
    final ambiente = clave.substring(23, 24);
    if (ambiente == '1') {
      return 'PRUEBAS';
    }
    if (ambiente == '2') {
      return 'PRODUCCION';
    }
    return null;
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

class FacturaPagoResumen {
  FacturaPagoResumen({
    required this.formaPago,
    required this.monto,
  });

  final String formaPago;
  final double monto;

  bool get esCredito {
    final normalized = formaPago.trim().toUpperCase();
    return normalized.contains('CREDITO') || normalized.contains('CRÉDITO');
  }

  bool get esEfectivo {
    return formaPago.trim().toUpperCase() == 'EFECTIVO';
  }

  factory FacturaPagoResumen.fromJson(Map<String, dynamic> json) {
    return FacturaPagoResumen(
      formaPago: json['formaPago']?.toString() ?? '',
      monto: parseDouble(json['monto']) ?? 0,
    );
  }
}
