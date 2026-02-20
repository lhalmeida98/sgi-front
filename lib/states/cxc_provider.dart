import '../domain/models/cuenta_por_cobrar.dart';
import '../services/cuentas_por_cobrar_service.dart';
import 'base_provider.dart';

class CxcProvider extends BaseProvider {
  CxcProvider(this._service);

  final CuentasPorCobrarService _service;
  List<CuentaPorCobrar> cuentas = [];

  Future<void> fetchCuentas({int? clienteId}) async {
    setLoading(true);
    try {
      cuentas = await _service.fetchCuentas(clienteId: clienteId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }
}
