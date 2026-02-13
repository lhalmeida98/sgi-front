import '../domain/models/documento_proveedor.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class DocumentosProveedorService {
  DocumentosProveedorService(this._client);

  final ApiClient _client;

  Future<List<DocumentoProveedor>> fetchDocumentos({int? proveedorId}) async {
    final response = proveedorId == null
        ? await _client.get('/api/documentos-proveedor')
        : await _client.get('/api/proveedores/$proveedorId/documentos');
    final items = extractList(response);
    return items.map(DocumentoProveedor.fromJson).toList();
  }

  Future<DocumentoProveedor> createDocumentoManual({
    required int proveedorId,
    required DocumentoProveedor documento,
  }) async {
    final response = await _client.post(
      '/api/proveedores/$proveedorId/documentos/confirmar',
      body: documento.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return documento;
    }
    return DocumentoProveedor.fromJson(map);
  }

  Future<DocumentoProveedor> uploadDocumentoXml({
    required int proveedorId,
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _client.postMultipart(
      '/api/proveedores/$proveedorId/documentos/xml',
      bytes: bytes,
      filename: filename,
      fields: const {},
      contentType: 'application/xml',
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return DocumentoProveedor();
    }
    return DocumentoProveedor.fromJson(map);
  }

  Future<DocumentoProveedor> registrarAutorizacion({
    required int proveedorId,
    required String autorizacion,
  }) async {
    final response = await _client.post(
      '/api/proveedores/$proveedorId/documentos/autorizacion',
      body: {
        'numeroAutorizacion': autorizacion,
      },
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return DocumentoProveedor();
    }
    return DocumentoProveedor.fromJson(map);
  }
}
