import '../domain/models/auth_info.dart';
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

  bool get isAdmin => (_authInfo?.rol ?? '').toUpperCase() == 'ADMIN';

  int? get empresaId => _authInfo?.empresaId;

  String? get rol => _authInfo?.rol;

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
          rolValue: stored.info.rol,
          empresaIdValue: stored.info.empresaId,
          emailValue: stored.email,
        );
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    try {
      final info = await _service.login(email: email, password: password);
      _authInfo = info;
      AuthSession.update(
        tokenValue: info.token,
        tipoValue: info.tipo,
        rolValue: info.rol,
        empresaIdValue: info.empresaId,
        emailValue: email,
      );
      await AuthStorage.save(info: info, email: email);
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
