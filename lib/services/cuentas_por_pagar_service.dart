import '../domain/models/cuenta_por_pagar.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class CuentasPorPagarService {
  CuentasPorPagarService(this._client);

  final ApiClient _client;

  Future<List<CuentaPorPagar>> fetchCuentas({int? proveedorId}) async {
    final response = await _client.get(
      '/api/cxp',
      query: proveedorId == null ? null : {'proveedorId': '$proveedorId'},
    );
    final items = extractList(response);
    return items.map(CuentaPorPagar.fromJson).toList();
  }
}
