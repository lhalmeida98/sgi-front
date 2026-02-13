import '../../utils/json_utils.dart';

class DocumentoProveedor {
  DocumentoProveedor({
    this.id,
    this.proveedorId,
    this.tipoDocumento,
    this.numeroDocumento,
    this.numeroAutorizacion,
    this.fechaEmision,
    this.fechaVencimiento,
    this.subtotal,
    this.impuestos,
    this.total,
    this.moneda,
    this.identificacionEmisor,
    this.razonSocialEmisor,
    this.saldo,
    this.estado,
    this.items = const [],
  });

  final int? id;
  final int? proveedorId;
  final String? tipoDocumento;
  final String? numeroDocumento;
  final String? numeroAutorizacion;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final double? subtotal;
  final double? impuestos;
  final double? total;
  final String? moneda;
  final String? identificacionEmisor;
  final String? razonSocialEmisor;
  final double? saldo;
  final String? estado;
  final List<DocumentoProveedorItem> items;

  factory DocumentoProveedor.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['detalle'] ?? json['detalles'];
    return DocumentoProveedor(
      id: parseInt(
        json['id'] ?? json['documentoId'] ?? json['documentoProveedorId'],
      ),
      proveedorId: parseInt(json['proveedorId'] ?? json['proveedor']?['id']),
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
      identificacionEmisor: json['identificacionEmisor']?.toString(),
      razonSocialEmisor: json['razonSocialEmisor']?.toString(),
      saldo: parseDouble(json['saldo'] ?? json['saldoPendiente']),
      estado: json['estado']?.toString() ?? json['status']?.toString(),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => DocumentoProveedorItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tipoDocumento != null) 'tipoDocumento': tipoDocumento,
      if (numeroDocumento != null) 'numeroDocumento': numeroDocumento,
      if (numeroAutorizacion != null && numeroAutorizacion!.isNotEmpty)
        'numeroAutorizacion': numeroAutorizacion,
      if (fechaEmision != null) 'fechaEmision': _formatDate(fechaEmision!),
      if (fechaVencimiento != null)
        'fechaVencimiento': _formatDate(fechaVencimiento!),
      if (subtotal != null) 'subtotal': subtotal,
      if (impuestos != null) 'impuestos': impuestos,
      if (total != null) 'total': total,
      if (moneda != null && moneda!.isNotEmpty) 'moneda': moneda,
      if (items.isNotEmpty) 'items': items.map((item) => item.toJson()).toList(),
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

class DocumentoProveedorItem {
  DocumentoProveedorItem({
    this.id,
    this.bodegaId,
    this.productoId,
    this.categoriaId,
    this.impuestoId,
    this.codigoPrincipal,
    this.codigoBarras,
    this.descripcion,
    this.precioVenta,
    this.cantidad,
    this.costoUnitario,
    this.subtotal,
  });

  final int? id;
  final int? bodegaId;
  final int? productoId;
  final int? categoriaId;
  final int? impuestoId;
  final String? codigoPrincipal;
  final String? codigoBarras;
  final String? descripcion;
  final double? precioVenta;
  final int? cantidad;
  final double? costoUnitario;
  final double? subtotal;

  factory DocumentoProveedorItem.fromJson(Map<String, dynamic> json) {
    return DocumentoProveedorItem(
      id: parseInt(json['id'] ?? json['itemId']),
      bodegaId: parseInt(json['bodegaId']),
      productoId: parseInt(json['productoId']),
      categoriaId: parseInt(json['categoriaId']),
      impuestoId: parseInt(json['impuestoId']),
      codigoPrincipal: json['codigoPrincipal']?.toString(),
      codigoBarras: json['codigoBarras']?.toString(),
      descripcion: json['descripcion']?.toString(),
      precioVenta: parseDouble(json['precioVenta']),
      cantidad: parseInt(json['cantidad']),
      costoUnitario: parseDouble(
        json['costoUnitario'] ?? json['precioUnitario'] ?? json['valorUnitario'],
      ),
      subtotal: parseDouble(json['subtotal'] ?? json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bodegaId != null) 'bodegaId': bodegaId,
      if (productoId != null) 'productoId': productoId,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (impuestoId != null) 'impuestoId': impuestoId,
      if (codigoPrincipal != null && codigoPrincipal!.isNotEmpty)
        'codigoPrincipal': codigoPrincipal,
      if (codigoBarras != null && codigoBarras!.isNotEmpty)
        'codigoBarras': codigoBarras,
      if (descripcion != null && descripcion!.isNotEmpty)
        'descripcion': descripcion,
      if (precioVenta != null) 'precioVenta': precioVenta,
      if (cantidad != null) 'cantidad': cantidad,
      if (costoUnitario != null) 'costoUnitario': costoUnitario,
      if (subtotal != null) 'subtotal': subtotal,
    };
  }
}
