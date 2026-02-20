import '../domain/models/accion.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class AccionesService {
  AccionesService(this._client);

  final ApiClient _client;

  Future<List<Accion>> fetchAcciones() async {
    final response = await _client.get('/api/acciones');
    final items = extractList(response);
    return items.map(Accion.fromJson).toList();
  }

  Future<Accion> createAccion(Accion accion) async {
    final response = await _client.post(
      '/api/acciones',
      body: accion.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return accion;
    }
    return Accion.fromJson(map);
  }

  Future<Accion> updateAccion(Accion accion) async {
    if (accion.id == null) {
      throw ApiException('Accion sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/acciones/${accion.id}',
      body: accion.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return accion;
    }
    return Accion.fromJson(map);
  }

  Future<void> deleteAccion(int accionId) async {
    await _client.delete('/api/acciones/$accionId');
  }
}
