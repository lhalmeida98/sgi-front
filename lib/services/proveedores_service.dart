import '../domain/models/proveedor.dart';
import '../domain/models/sri_consulta.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class ProveedoresService {
  ProveedoresService(this._client);

  final ApiClient _client;

  Future<List<Proveedor>> fetchProveedores() async {
    final response = await _client.get('/api/proveedores');
    final items = extractList(response);
    return items.map(Proveedor.fromJson).toList();
  }

  Future<Proveedor> createProveedor(Proveedor proveedor) async {
    final response = await _client.post(
      '/api/proveedores',
      body: proveedor.toCreateJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return proveedor;
    }
    return Proveedor.fromJson(map);
  }

  Future<Proveedor> updateProveedor(Proveedor proveedor) async {
    if (proveedor.id == null) {
      throw ApiException('Proveedor sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/proveedores/${proveedor.id}',
      body: proveedor.toUpdateJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return proveedor;
    }
    return Proveedor.fromJson(map);
  }

  Future<void> inactivateProveedor(int proveedorId) async {
    await _client.delete('/api/proveedores/$proveedorId');
  }

  Future<SriConsultaResult> consultarSri(String identificacion) async {
    final response = await _client.get(
      '/api/proveedores/consulta-sri',
      query: {'identificacion': identificacion},
    );
    if (response is Map) {
      return SriConsultaResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    }
    if (response is String && response.isNotEmpty) {
      return SriConsultaResult(encontrado: false, mensaje: response);
    }
    return SriConsultaResult(encontrado: false);
  }
}
