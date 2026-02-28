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
    final body = <String, dynamic>{
      'tipoIdentificacion': _tipoIdentificacionApi(cliente.tipoIdentificacion),
      'identificacion': cliente.identificacion,
      'razonSocial': cliente.razonSocial,
      'email': cliente.email,
      'direccion': cliente.direccion,
      'creditoDias': cliente.creditoDias ?? 0,
    };
    final response = await _client.put(
      '/api/clientes/${cliente.id}',
      body: body,
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return cliente;
    }
    return Cliente.fromJson(map);
  }

  String _tipoIdentificacionApi(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == '05' ||
        normalized == 'CEDULA' ||
        normalized == 'CÉDULA') {
      return 'CEDULA';
    }
    if (normalized == '04' || normalized == 'RUC') {
      return 'RUC';
    }
    if (normalized == '06' || normalized == 'PASAPORTE') {
      return 'PASAPORTE';
    }
    return normalized.isEmpty ? 'CEDULA' : normalized;
  }
}
