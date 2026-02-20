import '../domain/models/auth_info.dart';
import '../domain/models/menu_accion.dart';
import '../routing/app_sections.dart';
import '../services/auth_storage.dart';
import '../services/auth_service.dart';
import '../services/auth_session.dart';
import 'base_provider.dart';

class AuthProvider extends BaseProvider {
  AuthProvider(this._service);

  final AuthService _service;
  AuthInfo? _authInfo;
  bool _isRestoring = true;

  bool get isAuthenticated => _authInfo != null && AuthSession.isAuthenticated;

  bool get isAdmin => _authInfo?.isAdmin ?? false;

  int? get empresaId => _authInfo?.empresaId;

  int? get usuarioId => _authInfo?.usuarioId;

  String get rol => _authInfo?.rolPrincipal ?? '';

  List<String> get roles => _authInfo?.roles ?? [];

  List<String> get acciones =>
      _authInfo?.acciones.map((a) => a.nombre).toList() ?? [];

  List<MenuAccion> get menuAcciones => _authInfo?.acciones ?? [];

  bool canAccessSection(AppSection section) {
    if (section == AppSection.dashboard) {
      return true;
    }
    if (isAdmin) {
      return true;
    }
    final acciones = _authInfo?.acciones ?? [];
    if (acciones.isEmpty) {
      return section != AppSection.usuarios &&
          section != AppSection.empresas &&
          section != AppSection.roles;
    }
    return acciones.any(
      (accion) => resolveSectionForAccion(accion)?.section == section,
    );
  }

  String? get email => AuthSession.email;

  bool get isRestoring => _isRestoring;

  Future<void> restoreSession() async {
    if (!_isRestoring) {
      _isRestoring = true;
      notifyListeners();
    }
    try {
      final stored = await AuthStorage.read();
      if (stored != null) {
        _authInfo = stored.info;
        AuthSession.update(
          tokenValue: stored.info.token,
          tipoValue: stored.info.tipo,
          rolesValue: stored.info.roles,
          accionesValue: stored.info.acciones.map((a) => a.nombre).toList(),
          empresaIdValue: stored.info.empresaId,
          usuarioIdValue: stored.info.usuarioId,
          emailValue: stored.email,
        );
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String usuarioOrEmail,
    required String password,
  }) async {
    setLoading(true);
    try {
      final info = await _service.login(
        usuarioOrEmail: usuarioOrEmail,
        password: password,
      );
      _authInfo = info;
      final identifier = usuarioOrEmail.trim();
      AuthSession.update(
        tokenValue: info.token,
        tipoValue: info.tipo,
        rolesValue: info.roles,
        accionesValue: info.acciones.map((a) => a.nombre).toList(),
        empresaIdValue: info.empresaId,
        usuarioIdValue: info.usuarioId,
        emailValue: identifier,
      );
      await AuthStorage.save(info: info, email: identifier);
      setError(null);
      notifyListeners();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  void logout() {
    _authInfo = null;
    AuthSession.clear();
    AuthStorage.clear();
    setError(null);
    notifyListeners();
  }
}
