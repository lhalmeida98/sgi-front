import '../../utils/json_utils.dart';

class Empresa {
  Empresa({
    this.id,
    required this.ambiente,
    required this.tipoEmision,
    required this.razonSocial,
    required this.nombreComercial,
    required this.ruc,
    required this.dirMatriz,
    required this.estab,
    required this.ptoEmi,
    required this.secuencial,
    this.creditoDiasDefault,
  });

  final int? id;
  final String ambiente;
  final String tipoEmision;
  final String razonSocial;
  final String nombreComercial;
  final String ruc;
  final String dirMatriz;
  final String estab;
  final String ptoEmi;
  final String secuencial;
  final int? creditoDiasDefault;

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: parseInt(json['id'] ?? json['empresaId']),
      ambiente: (json['ambiente'] ?? '').toString(),
      tipoEmision: (json['tipoEmision'] ?? '').toString(),
      razonSocial: (json['razonSocial'] ?? '').toString(),
      nombreComercial: (json['nombreComercial'] ?? '').toString(),
      ruc: (json['ruc'] ?? '').toString(),
      dirMatriz: (json['dirMatriz'] ?? '').toString(),
      estab: (json['estab'] ?? '').toString(),
      ptoEmi: (json['ptoEmi'] ?? '').toString(),
      secuencial: (json['secuencial'] ?? '').toString(),
      creditoDiasDefault:
          parseInt(json['creditoDiasDefault'] ?? json['creditoDias']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ambiente': ambiente,
      'tipoEmision': tipoEmision,
      'razonSocial': razonSocial,
      'nombreComercial': nombreComercial,
      'ruc': ruc,
      'dirMatriz': dirMatriz,
      'estab': estab,
      'ptoEmi': ptoEmi,
      'secuencial': secuencial,
      if (creditoDiasDefault != null)
        'creditoDiasDefault': creditoDiasDefault,
    };
  }
}
