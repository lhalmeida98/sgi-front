import '../domain/models/cobro_cliente.dart';
import '../services/cobros_cliente_service.dart';
import 'base_provider.dart';

class CobrosClienteProvider extends BaseProvider {
  CobrosClienteProvider(this._service);

  final CobrosClienteService _service;
  List<CobroCliente> cobros = [];

  Future<void> fetchCobros({int? clienteId}) async {
    setLoading(true);
    try {
      cobros = await _service.fetchCobros(clienteId: clienteId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createCobro(CobroCliente cobro) async {
    setLoading(true);
    try {
      await _service.createCobro(cobro);
      await fetchCobros(clienteId: cobro.clienteId);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
