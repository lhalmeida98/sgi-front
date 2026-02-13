import '../domain/models/cuenta_por_pagar.dart';
import '../services/cuentas_por_pagar_service.dart';
import 'base_provider.dart';

class CxpProvider extends BaseProvider {
  CxpProvider(this._service);

  final CuentasPorPagarService _service;
  List<CuentaPorPagar> cuentas = [];

  Future<void> fetchCuentas({int? proveedorId}) async {
    setLoading(true);
    try {
      cuentas = await _service.fetchCuentas(proveedorId: proveedorId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }
}
