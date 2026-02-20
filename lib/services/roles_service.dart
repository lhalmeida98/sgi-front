import '../domain/models/accion.dart';
import '../domain/models/rol.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class RolesService {
  RolesService(this._client);

  final ApiClient _client;

  Future<List<Rol>> fetchRoles() async {
    final response = await _client.get('/api/roles');
    final items = extractList(response);
    return items.map(Rol.fromJson).toList();
  }

  Future<List<Accion>> fetchAccionesDisponibles() async {
    final response = await _client.get('/api/acciones');
    final items = extractList(response);
    return items.map(Accion.fromJson).toList();
  }

  Future<Rol> createRol(Rol rol) async {
    final response = await _client.post(
      '/api/roles',
      body: rol.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return rol;
    }
    return Rol.fromJson(map);
  }

  Future<Rol> updateRol(Rol rol) async {
    if (rol.id == null) {
      throw ApiException('Rol sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/roles/${rol.id}',
      body: rol.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return rol;
    }
    return Rol.fromJson(map);
  }

  Future<void> deleteRol(int rolId) async {
    await _client.delete('/api/roles/$rolId');
  }
}
