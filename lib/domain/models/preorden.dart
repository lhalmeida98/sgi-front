import '../../utils/json_utils.dart';

class Preorden {
  Preorden({
    this.id,
    required this.empresaId,
    required this.clienteId,
    required this.dirEstablecimiento,
    required this.moneda,
    required this.observaciones,
    required this.reservaInventario,
    required this.items,
  });

  final int? id;
  final int empresaId;
  final int clienteId;
  final String dirEstablecimiento;
  final String moneda;
  final String observaciones;
  final bool reservaInventario;
  final List<PreordenItem> items;

  factory Preorden.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Preorden(
      id: parseInt(json['id'] ?? json['preordenId']),
      empresaId: parseInt(json['empresaId']) ?? 0,
      clienteId: parseInt(json['clienteId']) ?? 0,
      dirEstablecimiento: (json['dirEstablecimiento'] ?? '').toString(),
      moneda: (json['moneda'] ?? '').toString(),
      observaciones: (json['observaciones'] ?? '').toString(),
      reservaInventario: parseBool(json['reservaInventario']) ?? false,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => PreordenItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'empresaId': empresaId,
      'clienteId': clienteId,
      'dirEstablecimiento': dirEstablecimiento,
      'moneda': moneda,
      'observaciones': observaciones,
      'reservaInventario': reservaInventario,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class PreordenItem {
  PreordenItem({
    this.id,
    this.bodegaId,
    required this.productoId,
    required this.cantidad,
    required this.descuento,
  });

  final int? id;
  final int? bodegaId;
  final int productoId;
  final double cantidad;
  final double descuento;

  factory PreordenItem.fromJson(Map<String, dynamic> json) {
    return PreordenItem(
      id: parseInt(json['id'] ?? json['itemId']),
      bodegaId: parseInt(json['bodegaId']),
      productoId: parseInt(json['productoId']) ?? 0,
      cantidad: parseDouble(json['cantidad']) ?? 0,
      descuento: parseDouble(json['descuento']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (bodegaId != null) 'bodegaId': bodegaId,
      'productoId': productoId,
      'cantidad': cantidad,
      'descuento': descuento,
    };
  }
}
