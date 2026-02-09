import '../domain/models/accion.dart';
import '../domain/models/rol.dart';
import '../services/roles_service.dart';
import 'base_provider.dart';

class RolesProvider extends BaseProvider {
  RolesProvider(this._service);

  final RolesService _service;
  List<Rol> roles = [];
  List<Accion> accionesDisponibles = [];

  Future<void> fetchRoles() async {
    setLoading(true);
    try {
      roles = await _service.fetchRoles();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchAccionesDisponibles() async {
    setLoading(true);
    try {
      accionesDisponibles = await _service.fetchAccionesDisponibles();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createRol(Rol rol) async {
    setLoading(true);
    try {
      await _service.createRol(rol);
      await fetchRoles();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
