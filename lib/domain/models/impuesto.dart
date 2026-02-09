import '../../utils/json_utils.dart';

class Impuesto {
  Impuesto({
    this.id,
    this.empresaId,
    required this.codigo,
    required this.codigoPorcentaje,
    required this.tarifa,
    required this.descripcion,
    required this.activo,
  });

  final int? id;
  final int? empresaId;
  final String codigo;
  final String codigoPorcentaje;
  final double tarifa;
  final String descripcion;
  final bool activo;

  factory Impuesto.fromJson(Map<String, dynamic> json) {
    return Impuesto(
      id: parseInt(json['id'] ?? json['impuestoId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      codigo: (json['codigo'] ?? '').toString(),
      codigoPorcentaje: (json['codigoPorcentaje'] ?? '').toString(),
      tarifa: parseDouble(json['tarifa']) ?? 0,
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: parseBool(json['activo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'codigoPorcentaje': codigoPorcentaje,
      'tarifa': tarifa,
      'descripcion': descripcion,
      'activo': activo,
    };
  }

  Impuesto copyWith({
    bool? activo,
  }) {
    return Impuesto(
      id: id,
      empresaId: empresaId,
      codigo: codigo,
      codigoPorcentaje: codigoPorcentaje,
      tarifa: tarifa,
      descripcion: descripcion,
      activo: activo ?? this.activo,
    );
  }
}
