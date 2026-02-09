import '../domain/models/producto.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class ProductosService {
  ProductosService(this._client);

  final ApiClient _client;

  Future<List<Producto>> fetchProductos() async {
    final response = await _client.get('/api/productos');
    final items = extractList(response);
    return items.map(Producto.fromJson).toList();
  }

  Future<Producto> createProducto(Producto producto) async {
    final response = await _client.post(
      '/api/productos',
      body: producto.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return producto;
    }
    return Producto.fromJson(map);
  }

  Future<Producto> updateProducto(Producto producto) async {
    if (producto.id == null) {
      throw ApiException('Producto sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/productos/${producto.id}',
      body: producto.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return producto;
    }
    return Producto.fromJson(map);
  }
}
