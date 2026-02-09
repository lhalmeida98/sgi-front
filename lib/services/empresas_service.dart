import '../domain/models/empresa.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class EmpresasService {
  EmpresasService(this._client);

  final ApiClient _client;

  Future<List<Empresa>> fetchEmpresas() async {
    final response = await _client.get('/api/empresas');
    final items = extractList(response);
    return items.map(Empresa.fromJson).toList();
  }

  Future<Empresa> createEmpresa(Empresa empresa) async {
    final response = await _client.post(
      '/api/empresas',
      body: empresa.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return empresa;
    }
    return Empresa.fromJson(map);
  }

  Future<Empresa> updateEmpresa(Empresa empresa) async {
    if (empresa.id == null) {
      throw ApiException('Empresa sin ID para actualizar.');
    }
    final response = await _client.put(
      '/api/empresas/${empresa.id}',
      body: empresa.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return empresa;
    }
    return Empresa.fromJson(map);
  }

  Future<void> uploadFirma({
    required int empresaId,
    required List<int> bytes,
    required String filename,
    required String clave,
  }) async {
    await _client.postMultipart(
      '/api/empresas/$empresaId/firma',
      bytes: bytes,
      filename: filename,
      fields: {'clave': clave},
      contentType: 'application/x-pkcs12',
    );
  }

  Future<void> uploadLogo({
    required int empresaId,
    required List<int> bytes,
    required String filename,
  }) async {
    await _client.postMultipart(
      '/api/empresas/$empresaId/logo',
      bytes: bytes,
      filename: filename,
      fields: const {},
      contentType: _logoContentType(filename),
    );
  }

  String _logoContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.svg')) {
      return 'image/svg+xml';
    }
    return 'application/octet-stream';
  }
}
