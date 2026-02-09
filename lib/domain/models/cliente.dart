import '../../utils/json_utils.dart';

class Cliente {
  Cliente({
    this.id,
    this.empresaId,
    required this.tipoIdentificacion,
    required this.identificacion,
    required this.razonSocial,
    required this.email,
    required this.direccion,
  });

  final int? id;
  final int? empresaId;
  final String tipoIdentificacion;
  final String identificacion;
  final String razonSocial;
  final String email;
  final String direccion;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: parseInt(json['id'] ?? json['clienteId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      tipoIdentificacion: (json['tipoIdentificacion'] ?? '').toString(),
      identificacion: (json['identificacion'] ?? '').toString(),
      razonSocial: (json['razonSocial'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tipoIdentificacion': tipoIdentificacion,
      'identificacion': identificacion,
      'razonSocial': razonSocial,
      'email': email,
      'direccion': direccion,
    };
  }
}
