class AuthSession {
  static String? token;
  static String? tipo;
  static List<String> roles = [];
  static List<String> acciones = [];
  static int? empresaId;
  static int? usuarioId;
  static String? email;

  static bool get isAuthenticated => token != null && token!.isNotEmpty;

  static bool get isAdmin =>
      roles.any((rol) => rol.toUpperCase() == 'ADMIN');

  static String? get authHeader {
    if (!isAuthenticated) {
      return null;
    }
    final prefix = (tipo ?? 'Bearer').trim();
    return '$prefix $token';
  }

  static void update({
    required String tokenValue,
    required String tipoValue,
    required List<String> rolesValue,
    required List<String> accionesValue,
    required int empresaIdValue,
    int? usuarioIdValue,
    required String emailValue,
  }) {
    token = tokenValue;
    tipo = tipoValue;
    roles = List<String>.from(rolesValue);
    acciones = List<String>.from(accionesValue);
    empresaId = empresaIdValue;
    usuarioId = usuarioIdValue;
    email = emailValue;
  }

  static void clear() {
    token = null;
    tipo = null;
    roles = [];
    acciones = [];
    empresaId = null;
    usuarioId = null;
    email = null;
  }
}
