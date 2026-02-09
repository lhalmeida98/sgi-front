import '../domain/models/preorden.dart';
import '../services/preordenes_service.dart';
import 'base_provider.dart';

class PreordenesProvider extends BaseProvider {
  PreordenesProvider(this._service);

  final PreordenesService _service;
  List<Preorden> preordenes = [];

  Future<void> fetchPreordenes() async {
    setLoading(true);
    try {
      preordenes = await _service.fetchPreordenes();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createPreorden(Preorden preorden) async {
    setLoading(true);
    try {
      await _service.createPreorden(preorden);
      await fetchPreordenes();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updatePreorden(Preorden preorden) async {
    setLoading(true);
    try {
      await _service.updatePreorden(preorden);
      await fetchPreordenes();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
