import '../domain/models/cliente.dart';
import '../services/clientes_service.dart';
import 'base_provider.dart';

class ClientesProvider extends BaseProvider {
  ClientesProvider(this._service);

  final ClientesService _service;
  List<Cliente> clientes = [];

  Future<void> fetchClientes() async {
    setLoading(true);
    try {
      clientes = await _service.fetchClientes();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createCliente(Cliente cliente) async {
    setLoading(true);
    try {
      await _service.createCliente(cliente);
      await fetchClientes();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateCliente(Cliente cliente) async {
    setLoading(true);
    try {
      await _service.updateCliente(cliente);
      await fetchClientes();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
