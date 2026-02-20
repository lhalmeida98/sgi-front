import '../domain/models/documento_cliente.dart';
import '../services/documentos_cliente_service.dart';
import 'base_provider.dart';

class DocumentosClienteProvider extends BaseProvider {
  DocumentosClienteProvider(this._service);

  final DocumentosClienteService _service;
  List<DocumentoCliente> documentos = [];

  Future<void> fetchDocumentos({int? clienteId}) async {
    setLoading(true);
    try {
      documentos = await _service.fetchDocumentos(clienteId: clienteId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> actualizarEstado({
    required int documentoId,
    required String estado,
    String? motivo,
    int? clienteId,
  }) async {
    setLoading(true);
    try {
      await _service.updateEstado(
        documentoId: documentoId,
        estado: estado,
        motivo: motivo,
      );
      await fetchDocumentos(clienteId: clienteId);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
