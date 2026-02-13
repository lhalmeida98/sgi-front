import '../domain/models/inventario.dart';
import '../domain/models/inventario_producto_disponible.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class InventariosService {
  InventariosService(this._client);

  final ApiClient _client;

  Future<List<Inventario>> fetchInventarios() async {
    final response = await _client.get('/api/inventarios');
    final items = extractList(response);
    final result = <Inventario>[];
    for (final raw in items) {
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        final bodegas = data['bodegas'];
        if (bodegas is List) {
          if (bodegas.isEmpty) {
            result.add(Inventario.fromJson(data));
          } else {
            for (final bodegaRaw in bodegas.whereType<Map>()) {
              final merged = Map<String, dynamic>.from(data);
              merged.addAll(Map<String, dynamic>.from(bodegaRaw));
              merged['productoNombre'] = data['productoNombre'];
              merged['precioVenta'] = data['precioVenta'];
              merged['stockGlobal'] = data['stockGlobal'];
              merged['stockReservadoGlobal'] = data['stockReservadoGlobal'];
              merged['costoPromedioGlobal'] = data['costoPromedioGlobal'];
              merged['margenPorcentajeGlobal'] = data['margenPorcentaje'];
              merged['bodegaId'] = bodegaRaw['bodegaId'];
              merged['bodegaNombre'] = bodegaRaw['bodegaNombre'];
              merged['margenPorcentaje'] = bodegaRaw['margenPorcentaje'];
              result.add(Inventario.fromJson(merged));
            }
          }
          continue;
        }
        result.add(Inventario.fromJson(data));
      }
    }
    return result;
  }

  Future<Inventario> upsertInventario(Inventario inventario) async {
    final response = await _client.post(
      '/api/inventarios',
      body: inventario.toJson(),
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return inventario;
    }
    return Inventario.fromJson(map);
  }

  Future<Inventario> fetchInventarioDetalle({
    required int productoId,
    required int bodegaId,
  }) async {
    final response = await _client.get(
      '/api/inventarios/producto/$productoId/bodega/$bodegaId',
    );
    final map = extractMap(response);
    return Inventario.fromJson(map);
  }

  Future<List<InventarioProductoDisponible>> fetchProductosDisponibles(
    int bodegaId,
  ) async {
    final response =
        await _client.get('/api/inventarios/bodega/$bodegaId/productos-disponibles');
    final items = extractList(response);
    return items.map(InventarioProductoDisponible.fromJson).toList();
  }

  Future<InventarioProductoDisponible> fetchProductoDisponibleByCodigo({
    required int bodegaId,
    required String codigo,
  }) async {
    final response = await _client.get(
      '/api/inventarios/bodega/$bodegaId/productos-disponibles/buscar',
      query: {'codigo': codigo},
    );
    final map = extractMap(response);
    return InventarioProductoDisponible.fromJson(map);
  }

  Future<InventarioProductoDisponible> fetchProductoDisponibleDetalle({
    required int bodegaId,
    required int productoId,
  }) async {
    final response = await _client.get(
      '/api/inventarios/bodega/$bodegaId/productos-disponibles/$productoId',
    );
    final map = extractMap(response);
    return InventarioProductoDisponible.fromJson(map);
  }
}
