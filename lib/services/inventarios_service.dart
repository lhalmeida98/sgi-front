import '../domain/models/inventario.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class InventariosService {
  InventariosService(this._client);

  final ApiClient _client;

  Future<List<Inventario>> fetchInventarios() async {
    final response = await _client.get('/api/inventarios');
    final items = extractList(response);
    return items.map(Inventario.fromJson).toList();
  }

  Future<Inventario> upsertInventario(Inventario inventario) async {
    final response = await _client.post(
      '/api/inventarios',
      body: inventario.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return inventario;
    }
    return Inventario.fromJson(map);
  }
}
