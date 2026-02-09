import '../domain/models/impuesto.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class ImpuestosService {
  ImpuestosService(this._client);

  final ApiClient _client;

  Future<List<Impuesto>> fetchImpuestos() async {
    final response = await _client.get('/api/impuestos');
    final items = extractList(response);
    return items.map(Impuesto.fromJson).toList();
  }

  Future<Impuesto> createImpuesto(Impuesto impuesto) async {
    final response = await _client.post(
      '/api/impuestos',
      body: impuesto.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return impuesto;
    }
    return Impuesto.fromJson(map);
  }

  Future<Impuesto> updateImpuesto(Impuesto impuesto) async {
    if (impuesto.id == null) {
      throw ApiException('Impuesto sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/impuestos/${impuesto.id}',
      body: impuesto.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return impuesto;
    }
    return Impuesto.fromJson(map);
  }
}
