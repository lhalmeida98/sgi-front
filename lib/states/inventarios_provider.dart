import '../domain/models/inventario.dart';
import '../services/inventarios_service.dart';
import 'base_provider.dart';

class InventariosProvider extends BaseProvider {
  InventariosProvider(this._service);

  final InventariosService _service;
  List<Inventario> inventarios = [];

  Future<void> fetchInventarios() async {
    setLoading(true);
    try {
      inventarios = await _service.fetchInventarios();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> upsertInventario(Inventario inventario) async {
    setLoading(true);
    try {
      await _service.upsertInventario(inventario);
      await fetchInventarios();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
