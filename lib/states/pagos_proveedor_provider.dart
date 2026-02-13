import '../domain/models/pago_proveedor.dart';
import '../services/pagos_proveedor_service.dart';
import 'base_provider.dart';

class PagosProveedorProvider extends BaseProvider {
  PagosProveedorProvider(this._service);

  final PagosProveedorService _service;
  List<PagoProveedor> pagos = [];

  Future<void> fetchPagos({int? proveedorId}) async {
    setLoading(true);
    try {
      pagos = await _service.fetchPagos(proveedorId: proveedorId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createPago(PagoProveedor pago) async {
    setLoading(true);
    try {
      await _service.createPago(pago);
      await fetchPagos(proveedorId: pago.proveedorId);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
