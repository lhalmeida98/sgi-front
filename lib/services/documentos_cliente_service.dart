import '../domain/models/documento_cliente.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class DocumentosClienteService {
  DocumentosClienteService(this._client);

  final ApiClient _client;

  Future<List<DocumentoCliente>> fetchDocumentos({int? clienteId}) async {
    final response = clienteId == null
        ? await _client.get('/api/documentos-cliente')
        : await _client.get('/api/clientes/$clienteId/documentos');
    final items = extractList(response);
    return items.map(DocumentoCliente.fromJson).toList();
  }

  Future<void> updateEstado({
    required int documentoId,
    required String estado,
    String? motivo,
  }) async {
    await _client.patch(
      '/api/documentos-cliente/$documentoId/estado',
      body: {
        'estado': estado,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
  }
}
