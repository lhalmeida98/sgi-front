import '../domain/models/inventario.dart';
import '../domain/models/inventario_producto_disponible.dart';
import '../services/api_client.dart';
import '../services/inventarios_service.dart';
import 'base_provider.dart';

class InventariosProvider extends BaseProvider {
  InventariosProvider(this._service);

  final InventariosService _service;
  List<Inventario> inventarios = [];
  List<InventarioProductoDisponible> productosDisponibles = [];
  int? productosDisponiblesBodegaId;
  final Map<String, InventarioProductoDisponible> _disponiblesCache = {};

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

  Future<Inventario?> fetchInventarioDetalle({
    required int productoId,
    required int bodegaId,
  }) async {
    try {
      final detalle = await _service.fetchInventarioDetalle(
        productoId: productoId,
        bodegaId: bodegaId,
      );
      setError(null);
      return detalle;
    } catch (error) {
      setError(resolveError(error));
      return null;
    }
  }

  InventarioProductoDisponible? getDisponible(int productoId, int bodegaId) {
    final key = '$productoId@$bodegaId';
    final cached = _disponiblesCache[key];
    if (cached != null) {
      return cached;
    }
    for (final disponible in productosDisponibles) {
      if (disponible.productoId == productoId &&
          disponible.bodegaId == bodegaId) {
        return disponible;
      }
    }
    return null;
  }

  void clearProductosDisponibles() {
    productosDisponibles = [];
    productosDisponiblesBodegaId = null;
    _disponiblesCache.clear();
    notifyListeners();
  }

  Future<void> fetchProductosDisponibles(int bodegaId) async {
    setLoading(true);
    try {
      productosDisponibles =
          await _service.fetchProductosDisponibles(bodegaId);
      productosDisponiblesBodegaId = bodegaId;
      _disponiblesCache.removeWhere(
        (_, value) => value.bodegaId == bodegaId,
      );
      for (final disponible in productosDisponibles) {
        final key = '${disponible.productoId}@${disponible.bodegaId}';
        _disponiblesCache[key] = disponible;
      }
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<InventarioProductoDisponible?> fetchProductoDisponibleByCodigo({
    required int bodegaId,
    required String codigo,
  }) async {
    try {
      final disponible = await _service.fetchProductoDisponibleByCodigo(
        bodegaId: bodegaId,
        codigo: codigo,
      );
      final key = '${disponible.productoId}@${disponible.bodegaId}';
      _disponiblesCache[key] = disponible;
      if (productosDisponiblesBodegaId == bodegaId &&
          !productosDisponibles.any(
            (item) => item.productoId == disponible.productoId,
          )) {
        productosDisponibles = [...productosDisponibles, disponible];
        notifyListeners();
      }
      setError(null);
      return disponible;
    } on ApiException catch (error) {
      if (error.statusCode != 404) {
        setError(resolveError(error));
      } else {
        setError(null);
      }
      return null;
    } catch (error) {
      setError(resolveError(error));
      return null;
    }
  }

  Future<InventarioProductoDisponible?> fetchProductoDisponibleDetalle({
    required int bodegaId,
    required int productoId,
  }) async {
    try {
      final disponible = await _service.fetchProductoDisponibleDetalle(
        bodegaId: bodegaId,
        productoId: productoId,
      );
      final key = '${disponible.productoId}@${disponible.bodegaId}';
      _disponiblesCache[key] = disponible;
      if (productosDisponiblesBodegaId == bodegaId &&
          !productosDisponibles.any(
            (item) => item.productoId == disponible.productoId,
          )) {
        productosDisponibles = [...productosDisponibles, disponible];
        notifyListeners();
      }
      setError(null);
      return disponible;
    } on ApiException catch (error) {
      if (error.statusCode != 404) {
        setError(resolveError(error));
      } else {
        setError(null);
      }
      return null;
    } catch (error) {
      setError(resolveError(error));
      return null;
    }
  }
}
