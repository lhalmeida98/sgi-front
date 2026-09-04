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
    this.secuencialPruebas,
    this.obligadoContabilidad = false,
    this.regimenTributario = 'GENERAL',
    this.contribuyenteEspecial = false,
    this.numeroContribuyenteEspecial,
    this.agenteRetencion = false,
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
  final String? secuencialPruebas;
  final bool obligadoContabilidad;
  final String regimenTributario;
  final bool contribuyenteEspecial;
  final String? numeroContribuyenteEspecial;
  final bool agenteRetencion;
  final int? creditoDiasDefault;

  factory Empresa.fromJson(Map<String, dynamic> json) {
    final nested = json['empresa'];
    final source =
        nested is Map ? Map<String, dynamic>.from(nested) : <String, dynamic>{};

    String pick(List<String> keys) {
      for (final key in keys) {
        final sourceValue = source[key];
        if (sourceValue != null && sourceValue.toString().trim().isNotEmpty) {
          return sourceValue.toString();
        }
        final jsonValue = json[key];
        if (jsonValue != null && jsonValue.toString().trim().isNotEmpty) {
          return jsonValue.toString();
        }
      }
      return '';
    }

    return Empresa(
      id: parseInt(source['id'] ?? json['id'] ?? json['empresaId']),
      ambiente: pick(['ambiente']),
      tipoEmision: pick(['tipoEmision', 'tipo_emision']),
      razonSocial: pick([
        'razonSocial',
        'razon_social',
        'razon',
        'nombre',
      ]),
      nombreComercial: pick([
        'nombreComercial',
        'nombre_comercial',
        'nombreFantasia',
        'nombre_fantasia',
      ]),
      ruc: pick([
        'ruc',
        'identificacion',
        'numeroIdentificacion',
        'numero_identificacion',
      ]),
      dirMatriz: pick([
        'dirMatriz',
        'direccionMatriz',
        'direccion_matriz',
      ]),
      estab: pick(['estab', 'establecimiento']),
      ptoEmi: pick(['ptoEmi', 'puntoEmision', 'punto_emision']),
      secuencial: pick(['secuencial']),
      secuencialPruebas:
          pick(['secuencialPruebas', 'secuencial_pruebas']).trim().isEmpty
              ? null
              : pick(['secuencialPruebas', 'secuencial_pruebas']),
      obligadoContabilidad: parseBool(source['obligadoContabilidad'] ??
              json['obligadoContabilidad'] ??
              source['obligado_contabilidad'] ??
              json['obligado_contabilidad']) ??
          false,
      regimenTributario: pick(['regimenTributario', 'regimen_tributario'])
              .trim()
              .isNotEmpty
          ? pick(['regimenTributario', 'regimen_tributario'])
          : (parseBool(source['regimenRimpe'] ?? json['regimenRimpe']) ?? false)
              ? 'RIMPE_EMPRENDEDOR'
              : 'GENERAL',
      contribuyenteEspecial: parseBool(source['contribuyenteEspecial'] ??
              json['contribuyenteEspecial'] ??
              source['contribuyente_especial'] ??
              json['contribuyente_especial']) ??
          false,
      numeroContribuyenteEspecial:
          pick(['numeroContribuyenteEspecial', 'numero_contribuyente_especial'])
                  .trim()
                  .isEmpty
              ? null
              : pick([
                  'numeroContribuyenteEspecial',
                  'numero_contribuyente_especial',
                ]),
      agenteRetencion: parseBool(source['agenteRetencion'] ??
              json['agenteRetencion'] ??
              source['agente_retencion'] ??
              json['agente_retencion']) ??
          false,
      creditoDiasDefault: parseInt(source['creditoDiasDefault'] ??
          json['creditoDiasDefault'] ??
          source['creditoDias'] ??
          json['creditoDias']),
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
      if (secuencialPruebas != null) 'secuencialPruebas': secuencialPruebas,
      'obligadoContabilidad': obligadoContabilidad,
      'regimenTributario': regimenTributario,
      'regimenRimpe': regimenTributario.startsWith('RIMPE'),
      'contribuyenteEspecial': contribuyenteEspecial,
      if (numeroContribuyenteEspecial != null)
        'numeroContribuyenteEspecial': numeroContribuyenteEspecial,
      'agenteRetencion': agenteRetencion,
      if (creditoDiasDefault != null) 'creditoDiasDefault': creditoDiasDefault,
    };
  }
}
