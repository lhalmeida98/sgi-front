import '../domain/models/bodega.dart';
import '../services/bodegas_service.dart';
import 'base_provider.dart';

class BodegasProvider extends BaseProvider {
  BodegasProvider(this._service);

  final BodegasService _service;
  List<Bodega> bodegas = [];

  Future<void> fetchBodegas() async {
    setLoading(true);
    try {
      bodegas = await _service.fetchBodegas();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createBodega(Bodega bodega) async {
    setLoading(true);
    try {
      await _service.createBodega(bodega);
      await fetchBodegas();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateBodega(Bodega bodega) async {
    setLoading(true);
    try {
      await _service.updateBodega(bodega);
      await fetchBodegas();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
