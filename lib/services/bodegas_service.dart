import '../domain/models/bodega.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class BodegasService {
  BodegasService(this._client);

  final ApiClient _client;

  Future<List<Bodega>> fetchBodegas() async {
    final response = await _client.get('/api/bodegas');
    final items = extractList(response);
    return items.map(Bodega.fromJson).toList();
  }

  Future<Bodega> createBodega(Bodega bodega) async {
    final response = await _client.post(
      '/api/bodegas',
      body: bodega.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return bodega;
    }
    return Bodega.fromJson(map);
  }

  Future<Bodega> updateBodega(Bodega bodega) async {
    if (bodega.id == null) {
      throw ApiException('Bodega sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/bodegas/${bodega.id}',
      body: bodega.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return bodega;
    }
    return Bodega.fromJson(map);
  }
}
