import '../domain/models/empresa.dart';
import '../services/empresas_service.dart';
import 'base_provider.dart';

class EmpresasProvider extends BaseProvider {
  EmpresasProvider(this._service);

  final EmpresasService _service;
  List<Empresa> empresas = [];

  Future<void> fetchEmpresas() async {
    setLoading(true);
    try {
      empresas = await _service.fetchEmpresas();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<Empresa?> createEmpresa(Empresa empresa) async {
    setLoading(true);
    try {
      final created = await _service.createEmpresa(empresa);
      await fetchEmpresas();
      return created;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateEmpresa(Empresa empresa) async {
    setLoading(true);
    try {
      await _service.updateEmpresa(empresa);
      await fetchEmpresas();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> uploadFirma({
    required int empresaId,
    required List<int> bytes,
    required String filename,
    required String clave,
  }) async {
    setLoading(true);
    try {
      await _service.uploadFirma(
        empresaId: empresaId,
        bytes: bytes,
        filename: filename,
        clave: clave,
      );
      setError(null);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> uploadLogo({
    required int empresaId,
    required List<int> bytes,
    required String filename,
  }) async {
    setLoading(true);
    try {
      await _service.uploadLogo(
        empresaId: empresaId,
        bytes: bytes,
        filename: filename,
      );
      setError(null);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
