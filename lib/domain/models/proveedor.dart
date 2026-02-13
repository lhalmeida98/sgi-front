import '../../utils/json_utils.dart';

class Proveedor {
  Proveedor({
    this.id,
    this.empresaId,
    required this.tipoIdentificacion,
    required this.identificacion,
    required this.razonSocial,
    this.nombreComercial,
    required this.email,
    required this.telefono,
    required this.direccion,
    this.condicionesPago,
    this.activo,
  });

  final int? id;
  final int? empresaId;
  final String tipoIdentificacion;
  final String identificacion;
  final String razonSocial;
  final String? nombreComercial;
  final String email;
  final String telefono;
  final String direccion;
  final String? condicionesPago;
  final bool? activo;

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: parseInt(json['id'] ?? json['proveedorId']),
      empresaId: parseInt(json['empresaId'] ?? json['empresa']?['id']),
      tipoIdentificacion: (json['tipoIdentificacion'] ?? '').toString(),
      identificacion: (json['identificacion'] ?? '').toString(),
      razonSocial: (json['razonSocial'] ?? json['nombre'] ?? '').toString(),
      nombreComercial: json['nombreComercial']?.toString(),
      email: (json['email'] ?? '').toString(),
      telefono: (json['telefono'] ?? json['celular'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      condicionesPago: json['condicionesPago']?.toString(),
      activo: _parseActivo(json['activo'] ?? json['estado']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'tipoIdentificacion': tipoIdentificacion,
      'identificacion': identificacion,
      'razonSocial': razonSocial,
      if (nombreComercial != null && nombreComercial!.isNotEmpty)
        'nombreComercial': nombreComercial,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      if (condicionesPago != null && condicionesPago!.isNotEmpty)
        'condicionesPago': condicionesPago,
      if (activo != null) 'activo': activo,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'razonSocial': razonSocial,
      if (nombreComercial != null && nombreComercial!.isNotEmpty)
        'nombreComercial': nombreComercial,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      if (condicionesPago != null && condicionesPago!.isNotEmpty)
        'condicionesPago': condicionesPago,
      if (activo != null) 'activo': activo,
    };
  }

  static bool? _parseActivo(dynamic value) {
    if (value == null) {
      return null;
    }
    final boolValue = parseBool(value);
    if (boolValue != null) {
      return boolValue;
    }
    final text = value.toString().toLowerCase();
    if (text.contains('activo')) {
      return true;
    }
    if (text.contains('inactivo')) {
      return false;
    }
    return null;
  }
}
