import '../domain/models/documento_proveedor.dart';
import '../services/documentos_proveedor_service.dart';
import 'base_provider.dart';

class DocumentosProveedorProvider extends BaseProvider {
  DocumentosProveedorProvider(this._service);

  final DocumentosProveedorService _service;
  List<DocumentoProveedor> documentos = [];

  Future<void> fetchDocumentos({int? proveedorId}) async {
    setLoading(true);
    try {
      documentos = await _service.fetchDocumentos(proveedorId: proveedorId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createDocumentoManual({
    required int proveedorId,
    required DocumentoProveedor documento,
  }) async {
    setLoading(true);
    try {
      await _service.createDocumentoManual(
        proveedorId: proveedorId,
        documento: documento,
      );
      await fetchDocumentos(proveedorId: proveedorId);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<DocumentoProveedor?> previewDocumentoXml({
    required int proveedorId,
    required List<int> bytes,
    required String filename,
  }) async {
    setLoading(true);
    try {
      final preview = await _service.uploadDocumentoXml(
        proveedorId: proveedorId,
        bytes: bytes,
        filename: filename,
      );
      setError(null);
      return preview;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<DocumentoProveedor?> previewAutorizacion({
    required int proveedorId,
    required String autorizacion,
  }) async {
    setLoading(true);
    try {
      final preview = await _service.registrarAutorizacion(
        proveedorId: proveedorId,
        autorizacion: autorizacion,
      );
      setError(null);
      return preview;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }
}
