import '../domain/models/pago_proveedor.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class PagosProveedorService {
  PagosProveedorService(this._client);

  final ApiClient _client;

  Future<List<PagoProveedor>> fetchPagos({int? proveedorId}) async {
    final response = await _client.get(
      '/api/pagos-proveedor',
      query: proveedorId == null ? null : {'proveedorId': '$proveedorId'},
    );
    final items = extractList(response);
    return items.map(PagoProveedor.fromJson).toList();
  }

  Future<PagoProveedor> createPago(PagoProveedor pago) async {
    final response = await _client.post(
      '/api/pagos-proveedor',
      body: pago.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return pago;
    }
    return PagoProveedor.fromJson(map);
  }
}
