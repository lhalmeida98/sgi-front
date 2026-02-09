import '../domain/models/producto.dart';
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
}
