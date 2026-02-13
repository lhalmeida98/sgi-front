import '../domain/models/producto.dart';
import '../services/api_client.dart';
import '../services/productos_service.dart';
import 'base_provider.dart';

class ProductosProvider extends BaseProvider {
  ProductosProvider(this._service);

  final ProductosService _service;
  List<Producto> productos = [];

  Future<void> fetchProductos() async {
    setLoading(true);
    try {
      productos = await _service.fetchProductos();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createProducto(Producto producto) async {
    setLoading(true);
    try {
      await _service.createProducto(producto);
      await fetchProductos();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProducto(Producto producto) async {
    setLoading(true);
    try {
      await _service.updateProducto(producto);
      await fetchProductos();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<Producto?> fetchProductoByCodigo(String codigo) async {
    try {
      final producto = await _service.fetchProductoByCodigo(codigo);
      final exists = productos.any((item) => item.id == producto.id);
      if (!exists) {
        productos = [...productos, producto];
        notifyListeners();
      }
      setError(null);
      return producto;
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

  void upsertProductoLocal(Producto producto) {
    final index = productos.indexWhere((item) => item.id == producto.id);
    if (index >= 0) {
      productos[index] = producto;
    } else {
      productos = [...productos, producto];
    }
    notifyListeners();
  }
}
