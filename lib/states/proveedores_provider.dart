import '../domain/models/proveedor.dart';
import '../domain/models/sri_consulta.dart';
import '../services/proveedores_service.dart';
import 'base_provider.dart';

class ProveedoresProvider extends BaseProvider {
  ProveedoresProvider(this._service);

  final ProveedoresService _service;
  List<Proveedor> proveedores = [];

  Future<void> fetchProveedores() async {
    setLoading(true);
    try {
      proveedores = await _service.fetchProveedores();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createProveedor(Proveedor proveedor) async {
    setLoading(true);
    try {
      await _service.createProveedor(proveedor);
      await fetchProveedores();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProveedor(Proveedor proveedor) async {
    setLoading(true);
    try {
      await _service.updateProveedor(proveedor);
      await fetchProveedores();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> inactivateProveedor(int proveedorId) async {
    setLoading(true);
    try {
      await _service.inactivateProveedor(proveedorId);
      await fetchProveedores();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<SriConsultaResult> consultarSri(String identificacion) async {
    try {
      final result = await _service.consultarSri(identificacion);
      setError(null);
      return result;
    } catch (error) {
      setError(resolveError(error));
      rethrow;
    }
  }
}
