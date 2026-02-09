import '../domain/models/cliente.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class ClientesService {
  ClientesService(this._client);

  final ApiClient _client;

  Future<List<Cliente>> fetchClientes() async {
    final response = await _client.get('/api/clientes');
    final items = extractList(response);
    return items.map(Cliente.fromJson).toList();
  }

  Future<Cliente> createCliente(Cliente cliente) async {
    final response = await _client.post(
      '/api/clientes',
      body: cliente.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return cliente;
    }
    return Cliente.fromJson(map);
  }

  Future<Cliente> updateCliente(Cliente cliente) async {
    if (cliente.id == null) {
      throw ApiException('Cliente sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/clientes/${cliente.id}',
      body: cliente.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return cliente;
    }
    return Cliente.fromJson(map);
  }
}
