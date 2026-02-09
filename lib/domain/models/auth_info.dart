import '../../utils/json_utils.dart';

class AuthInfo {
  AuthInfo({
    required this.token,
    required this.tipo,
    required this.rol,
    required this.empresaId,
  });

  final String token;
  final String tipo;
  final String rol;
  final int empresaId;

  factory AuthInfo.fromJson(Map<String, dynamic> json) {
    return AuthInfo(
      token: (json['token'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'Bearer').toString(),
      rol: (json['rol'] ?? '').toString(),
      empresaId: parseInt(json['empresaId']) ?? 0,
    );
  }
}
