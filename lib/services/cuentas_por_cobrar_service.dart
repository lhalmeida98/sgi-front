import '../domain/models/cuenta_por_cobrar.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class CuentasPorCobrarService {
  CuentasPorCobrarService(this._client);

  final ApiClient _client;

  Future<List<CuentaPorCobrar>> fetchCuentas({int? clienteId}) async {
    final response = await _client.get(
      '/api/cxc',
      query: clienteId == null ? null : {'clienteId': '$clienteId'},
    );
    final items = extractList(response);
    return items.map(CuentaPorCobrar.fromJson).toList();
  }
}
