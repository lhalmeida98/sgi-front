import '../../utils/json_utils.dart';
import 'empresa.dart';

class UsuarioEmpresa {
  UsuarioEmpresa({
    required this.empresaId,
    required this.principal,
    this.empresa,
  });

  final int empresaId;
  final bool principal;
  final Empresa? empresa;

  factory UsuarioEmpresa.fromJson(Map<String, dynamic> json) {
    final empresaMap = json['empresa'];
    final empresa = empresaMap is Map
        ? Empresa.fromJson(Map<String, dynamic>.from(empresaMap))
        : null;
    final empresaId =
        parseInt(json['empresaId'] ?? empresa?.id ?? json['id']) ?? 0;
    return UsuarioEmpresa(
      empresaId: empresaId,
      principal: parseBool(json['principal']) ?? false,
      empresa: empresa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empresaId': empresaId,
      'principal': principal,
    };
  }
}
