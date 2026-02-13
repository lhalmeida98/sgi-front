import '../../utils/json_utils.dart';

class SriConsultaResult {
  SriConsultaResult({
    required this.encontrado,
    this.mensaje,
    this.data,
  });

  final bool encontrado;
  final String? mensaje;
  final SriConsultaData? data;

  factory SriConsultaResult.fromJson(Map<String, dynamic> json) {
    return SriConsultaResult(
      encontrado: parseBool(json['encontrado']) ?? false,
      mensaje: json['mensaje']?.toString(),
      data: json['data'] is Map
          ? SriConsultaData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }
}

class SriConsultaData {
  SriConsultaData({
    this.numeroRuc,
    this.razonSocial,
    this.estadoContribuyenteRuc,
    this.actividadEconomicaPrincipal,
    this.tipoContribuyente,
    this.regimen,
    this.categoria,
    this.obligadoLlevarContabilidad,
    this.agenteRetencion,
    this.contribuyenteEspecial,
    this.contribuyenteFantasma,
    this.transaccionesInexistente,
  });

  final String? numeroRuc;
  final String? razonSocial;
  final String? estadoContribuyenteRuc;
  final String? actividadEconomicaPrincipal;
  final String? tipoContribuyente;
  final String? regimen;
  final String? categoria;
  final String? obligadoLlevarContabilidad;
  final String? agenteRetencion;
  final String? contribuyenteEspecial;
  final String? contribuyenteFantasma;
  final String? transaccionesInexistente;

  factory SriConsultaData.fromJson(Map<String, dynamic> json) {
    return SriConsultaData(
      numeroRuc: json['numeroRuc']?.toString(),
      razonSocial: json['razonSocial']?.toString(),
      estadoContribuyenteRuc: json['estadoContribuyenteRuc']?.toString(),
      actividadEconomicaPrincipal:
          json['actividadEconomicaPrincipal']?.toString(),
      tipoContribuyente: json['tipoContribuyente']?.toString(),
      regimen: json['regimen']?.toString(),
      categoria: json['categoria']?.toString(),
      obligadoLlevarContabilidad:
          json['obligadoLlevarContabilidad']?.toString(),
      agenteRetencion: json['agenteRetencion']?.toString(),
      contribuyenteEspecial: json['contribuyenteEspecial']?.toString(),
      contribuyenteFantasma: json['contribuyenteFantasma']?.toString(),
      transaccionesInexistente: json['transaccionesInexistente']?.toString(),
    );
  }
}
