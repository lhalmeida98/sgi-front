import '../domain/models/categoria.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class CategoriasService {
  CategoriasService(this._client);

  final ApiClient _client;

  Future<List<Categoria>> fetchCategorias() async {
    final response = await _client.get('/api/categorias');
    final items = extractList(response);
    return items.map(Categoria.fromJson).toList();
  }

  Future<Categoria> createCategoria(Categoria categoria) async {
    final response = await _client.post(
      '/api/categorias',
      body: categoria.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return categoria;
    }
    return Categoria.fromJson(map);
  }

  Future<Categoria> updateCategoria(Categoria categoria) async {
    if (categoria.id == null) {
      throw ApiException('Categoria sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/categorias/${categoria.id}',
      body: categoria.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return categoria;
    }
    return Categoria.fromJson(map);
  }
}
