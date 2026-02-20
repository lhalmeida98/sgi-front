import '../../utils/json_utils.dart';

class CxcAgingReport {
  CxcAgingReport({
    required this.vencidas,
    required this.porVencer7,
    required this.porVencer15,
    required this.porVencer30,
    required this.futuras,
  });

  final double vencidas;
  final double porVencer7;
  final double porVencer15;
  final double porVencer30;
  final double futuras;

  double get total =>
      vencidas + porVencer7 + porVencer15 + porVencer30 + futuras;

  factory CxcAgingReport.fromJson(Map<String, dynamic> json) {
    return CxcAgingReport(
      vencidas: parseDouble(json['vencidas'] ?? json['vencida']) ?? 0,
      porVencer7:
          parseDouble(json['porVencer7'] ?? json['porVencer_7']) ?? 0,
      porVencer15:
          parseDouble(json['porVencer15'] ?? json['porVencer_15']) ?? 0,
      porVencer30:
          parseDouble(json['porVencer30'] ?? json['porVencer_30']) ?? 0,
      futuras: parseDouble(json['futuras'] ?? json['futura']) ?? 0,
    );
  }
}
