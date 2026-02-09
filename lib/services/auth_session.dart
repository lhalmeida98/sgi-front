class AuthSession {
  static String? token;
  static String? tipo;
  static String? rol;
  static int? empresaId;
  static String? email;

  static bool get isAuthenticated => token != null && token!.isNotEmpty;

  static bool get isAdmin => (rol ?? '').toUpperCase() == 'ADMIN';

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
    required String rolValue,
    required int empresaIdValue,
    required String emailValue,
  }) {
    token = tokenValue;
    tipo = tipoValue;
    rol = rolValue;
    empresaId = empresaIdValue;
    email = emailValue;
  }

  static void clear() {
    token = null;
    tipo = null;
    rol = null;
    empresaId = null;
    email = null;
  }
}
