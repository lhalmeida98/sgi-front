import '../domain/models/usuario.dart';
import '../services/usuarios_service.dart';
import 'base_provider.dart';

class UsuariosProvider extends BaseProvider {
  UsuariosProvider(this._service);

  final UsuariosService _service;
  List<Usuario> usuarios = [];
  bool _includeAll = false;

  Future<void> fetchUsuarios({bool includeAll = false}) async {
    _includeAll = includeAll;
    setLoading(true);
    try {
      usuarios = await _service.fetchUsuarios(includeAll: includeAll);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createUsuario(Usuario usuario, {String? password}) async {
    setLoading(true);
    try {
      await _service.createUsuario(usuario, password: password);
      await fetchUsuarios(includeAll: _includeAll);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateUsuario(Usuario usuario, {String? password}) async {
    setLoading(true);
    try {
      await _service.updateUsuario(usuario, password: password);
      await fetchUsuarios(includeAll: _includeAll);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteUsuario(int usuarioId) async {
    setLoading(true);
    try {
      await _service.deleteUsuario(usuarioId);
      await fetchUsuarios(includeAll: _includeAll);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
