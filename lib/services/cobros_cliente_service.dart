import '../domain/models/cobro_cliente.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class CobrosClienteService {
  CobrosClienteService(this._client);

  final ApiClient _client;

  Future<List<CobroCliente>> fetchCobros({int? clienteId}) async {
    final response = await _client.get(
      '/api/cobros-cliente',
      query: clienteId == null ? null : {'clienteId': '$clienteId'},
    );
    final items = extractList(response);
    return items.map(CobroCliente.fromJson).toList();
  }

  Future<CobroCliente> createCobro(CobroCliente cobro) async {
    final response = await _client.post(
      '/api/cobros-cliente',
      body: cobro.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return cobro;
    }
    return CobroCliente.fromJson(map);
  }
}
