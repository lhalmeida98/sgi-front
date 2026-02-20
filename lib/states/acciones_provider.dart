import '../domain/models/accion.dart';
import '../services/acciones_service.dart';
import 'base_provider.dart';

class AccionesProvider extends BaseProvider {
  AccionesProvider(this._service);

  final AccionesService _service;
  List<Accion> acciones = [];

  Future<void> fetchAcciones() async {
    setLoading(true);
    try {
      acciones = await _service.fetchAcciones();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createAccion(Accion accion) async {
    setLoading(true);
    try {
      await _service.createAccion(accion);
      await fetchAcciones();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateAccion(Accion accion) async {
    setLoading(true);
    try {
      await _service.updateAccion(accion);
      await fetchAcciones();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteAccion(int accionId) async {
    setLoading(true);
    try {
      await _service.deleteAccion(accionId);
      await fetchAcciones();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
