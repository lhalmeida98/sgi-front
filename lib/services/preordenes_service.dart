import '../domain/models/preorden.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class PreordenesService {
  PreordenesService(this._client);

  final ApiClient _client;

  Future<List<Preorden>> fetchPreordenes() async {
    final response = await _client.get('/api/preordenes');
    final items = extractList(response);
    return items.map(Preorden.fromJson).toList();
  }

  Future<Preorden> createPreorden(Preorden preorden) async {
    final response = await _client.post(
      '/api/preordenes',
      body: preorden.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return preorden;
    }
    return Preorden.fromJson(map);
  }

  Future<Preorden> updatePreorden(Preorden preorden) async {
    if (preorden.id == null) {
      throw ApiException('Preorden sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/preordenes/${preorden.id}',
      body: preorden.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return preorden;
    }
    return Preorden.fromJson(map);
  }
}
