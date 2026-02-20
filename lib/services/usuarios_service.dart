import '../domain/models/usuario.dart';
import '../domain/models/usuario_empresa.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class UsuariosService {
  UsuariosService(this._client);

  final ApiClient _client;

  Future<List<Usuario>> fetchUsuarios({bool includeAll = false}) async {
    final response = await _client.get(
      includeAll ? '/api/usuarios/todos' : '/api/usuarios',
    );
    final items = extractList(response);
    return items.map(Usuario.fromJson).toList();
  }

  Future<List<UsuarioEmpresa>> fetchUsuarioEmpresas(int usuarioId) async {
    final response = await _client.get('/api/usuarios/$usuarioId/empresas');
    final items = extractList(response);
    return items.map(UsuarioEmpresa.fromJson).toList();
  }

  Future<Usuario> createUsuario(Usuario usuario, {String? password}) async {
    final response = await _client.post(
      '/api/usuarios',
      body: usuario.toJson(password: password),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return usuario;
    }
    return Usuario.fromJson(map);
  }

  Future<Usuario> updateUsuario(Usuario usuario, {String? password}) async {
    if (usuario.id == null) {
      throw ApiException('Usuario sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/usuarios/${usuario.id}',
      body: usuario.toJson(password: password),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return usuario;
    }
    return Usuario.fromJson(map);
  }

  Future<void> deleteUsuario(int usuarioId) async {
    await _client.delete('/api/usuarios/$usuarioId');
  }
}
