import '../domain/models/usuario.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class UsuariosService {
  UsuariosService(this._client);

  final ApiClient _client;

  Future<List<Usuario>> fetchUsuarios() async {
    final response = await _client.get('/api/usuarios');
    final items = extractList(response);
    return items.map(Usuario.fromJson).toList();
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
}
